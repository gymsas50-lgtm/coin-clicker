// Spring-assisted heavy lid. Fixed-step torque integration, sampled independently of refresh rate.
const STEP=1/240,MAX=1.62;
export function createHingeMotion(opening,initial=0) {
  const samples=[initial];let angle=initial,velocity=0;
  const seconds=opening?3.8:2.5;
  for(let i=1;i<=Math.ceil(seconds/STEP);i++) {
    // Gravity closes the lid; a preloaded hinge spring lifts it after unlocking.
    const gravity=-5.8*Math.cos(angle);
    const spring=opening?16*(1.82-angle):-3.0;
    const friction=opening?2.4:.65;
    const acceleration=spring+gravity-friction*velocity;
    velocity+=acceleration*STEP;angle+=velocity*STEP;
    if(angle>MAX){angle=MAX;velocity=-Math.abs(velocity)*.22;}
    if(angle<0){angle=0;velocity=Math.abs(velocity)*.17;}
    if((opening&&angle>MAX-.001||!opening&&angle<.001)&&Math.abs(velocity)<.045){angle=opening?MAX:0;velocity=0;}
    samples.push(angle);
  }
  return elapsed=>{
    if(elapsed<=0)return initial;
    const index=elapsed/STEP,lo=Math.floor(index);
    if(lo>=samples.length-1)return opening?MAX:0;
    const fraction=index-lo;return samples[lo]+(samples[lo+1]-samples[lo])*fraction;
  };
}
