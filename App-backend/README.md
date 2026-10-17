# App-backend

Profiles, CVs, taxonomy and job/match APIs. The Python CV parser is owned here under `extractor/`.

Runtime source stays inside this folder. Install pinned dependencies with npm ci, configure an ignored .env using .env.example and run npm start with Node 24.22.0. This Dockerfile builds from this folder alone.

CV uploads start `extractor/worker.py` as a child process only when parsing is needed, then the worker exits. There is no always-running Python HTTP server, extractor domain, port, URL or access key. Node sends the file through stdin and receives bounded JSON through stdout; database, identity, AI and mail credentials are excluded from the worker environment. One parser runs at a time per App process, with a 10-second deadline and 300 KB output cap. Invalid inputs retain the existing CV error codes; process failures return a generic 503.

The `Production` Docker target installs Python, a private virtual environment and the pinned `extractor/requirements.txt`, and copies the owned parser. Its only startup command remains `node index.js`; no separate extractor deployment is needed. Remove retired `CV_EXTRACTOR_URL` and `CV_EXTRACTOR_KEY` settings from Dokploy. Existing values are ignored. The image must be deployed from this source before this behavior is active; no image build or deployment was run here.

For direct local startup, install Python 3 with `pypdf` from `extractor/requirements.txt` in the selected interpreter environment. App uses `python` on Windows and `python3` on Linux; an activated virtual environment can supply that interpreter through PATH. No background parser is required.

See [backend operations and API connections](../Gateway-backene/BACKENDS.md) and [local environment](../Gateway-backene/tooling/ENVIRONMENT.md).
