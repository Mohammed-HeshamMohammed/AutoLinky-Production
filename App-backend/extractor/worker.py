"""One bounded parse per process; no database, identity, AI or mail access."""
import dataclasses
import io
import json
import sys
import zipfile

from cv_file import CVFileError, MAX_BYTES, extract, extract_links

def process(data):
    if not data:
        raise CVFileError('cv_empty', 400)
    if len(data) > MAX_BYTES:
        raise CVFileError('cv_too_large', 413)
    if data.startswith(b'PK\x03\x04'):
        try:
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                entries = archive.infolist()
                if len(entries) > 500 or sum(entry.file_size for entry in entries) > 32 * 1024 * 1024:
                    raise CVFileError('cv_unreadable')
                if any(entry.file_size > 1024 * 1024 and entry.file_size / max(1, entry.compress_size) > 100 for entry in entries):
                    raise CVFileError('cv_unreadable')
        except CVFileError:
            raise
        except Exception:
            raise CVFileError('cv_unreadable')
    result = dataclasses.asdict(extract(data))
    result['links'] = extract_links(data, result['file_type'])
    return result

if __name__ == '__main__':
    try:
        result = process(sys.stdin.buffer.read(MAX_BYTES + 1))
        print(json.dumps({'result': result}, ensure_ascii=True))
    except CVFileError as error:
        print(json.dumps({'error': error.code, 'status': error.status}))
    except Exception:
        print(json.dumps({'error': 'cv_unreadable', 'status': 422}))
