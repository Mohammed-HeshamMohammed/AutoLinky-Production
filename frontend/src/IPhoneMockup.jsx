import mockup from './iphoneMockup.json';
import './iphone-mockup.css';

const aperture={
  left:`${mockup.screen.x/mockup.width*100}%`,
  top:`${mockup.screen.y/mockup.height*100}%`,
  width:`${mockup.screen.width/mockup.width*100}%`,
  height:`${mockup.screen.height/mockup.height*100}%`,
  borderRadius:`${mockup.screen.radius/mockup.screen.width*100}% / ${mockup.screen.radius/mockup.screen.height*100}%`,
  background:mockup.background,
};

export default function IPhoneMockup({src,alt,className='',loading='lazy',decoding='async',fetchPriority}){
  const captureSrc=mockup.captureRevision?`${src}${src.includes('?')?'&':'?'}v=${mockup.captureRevision}`:src;
  return <span className={`iphone-mockup${className?` ${className}`:''}`} style={{aspectRatio:`${mockup.width} / ${mockup.height}`}}>
    <span className="iphone-mockup__screen" style={aperture}>
      <img className="iphone-mockup__capture" src={captureSrc} width="1179" height="2556" loading={loading} decoding={decoding} fetchPriority={fetchPriority} alt={alt}/>
    </span>
    <img className="iphone-mockup__frame" src={mockup.frameSrc} width={mockup.width} height={mockup.height} loading={loading} decoding="async" alt="" aria-hidden="true" draggable="false"/>
  </span>;
}
