import svgPaths from "./svg-k0taemj4jp";
import imgMask from "figma:asset/dc2b7817113ba588d4edef2c854b7c05ad63da01.png";

function Image() {
  return (
    <div className="absolute contents left-[14px] top-[14px]" data-name="Image">
      <div className="absolute h-[330px] left-[14px] pointer-events-none rounded-[12px] top-[14px] w-[358px]" data-name="Mask">
        <div aria-hidden="true" className="absolute inset-0 rounded-[12px]">
          <div className="absolute bg-[#f6eded] inset-0 rounded-[12px]" />
          <img alt="" className="absolute max-w-none object-50%-50% object-cover rounded-[12px] size-full" src={imgMask} />
        </div>
        <div aria-hidden="true" className="absolute border border-black border-solid inset-[-0.5px] rounded-[12.5px]" />
      </div>
    </div>
  );
}

function Score() {
  return (
    <div className="absolute bottom-[87.16%] left-0 overflow-clip right-[63.13%] top-0" data-name="Score">
      <div className="absolute bottom-0 left-0 right-[88.64%] top-0" data-name="Icon">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 15 14">
          <path clipRule="evenodd" d={svgPaths.p284b56f0} fill="var(--fill-0, #F6BB35)" fillRule="evenodd" id="Icon" />
        </svg>
      </div>
      <div className="absolute bottom-0 left-[16.67%] right-[71.97%] top-0" data-name="Icon">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 15 14">
          <path clipRule="evenodd" d={svgPaths.p284b56f0} fill="var(--fill-0, #F6BB35)" fillRule="evenodd" id="Icon" />
        </svg>
      </div>
      <div className="absolute bottom-0 left-[33.33%] right-[55.3%] top-0" data-name="Icon">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 15 14">
          <path clipRule="evenodd" d={svgPaths.p284b56f0} fill="var(--fill-0, #F6BB35)" fillRule="evenodd" id="Icon" />
        </svg>
      </div>
      <div className="absolute bottom-0 left-1/2 right-[38.64%] top-0" data-name="Icon">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 15 14">
          <path clipRule="evenodd" d={svgPaths.p284b56f0} fill="var(--fill-0, #F6BB35)" fillRule="evenodd" id="Icon" />
        </svg>
      </div>
      <div className="absolute bottom-0 left-[66.67%] right-[21.97%] top-0" data-name="Icon">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 15 14">
          <path clipRule="evenodd" d={svgPaths.p284b56f0} fill="var(--fill-0, #F6BB35)" fillRule="evenodd" id="Icon" />
        </svg>
      </div>
      <p className="absolute font-['Sulphur_Point:Regular',sans-serif] leading-[normal] left-[83.33%] not-italic right-[4.54%] text-[#ded7d7] text-[12px] text-nowrap top-[calc(50%-7px)] tracking-[1px] whitespace-pre">4.9</p>
    </div>
  );
}

function Info() {
  return (
    <div className="absolute h-[109px] left-[14px] top-[358px] w-[358px]" data-name="Info">
      <div className="h-[109px] overflow-clip relative rounded-[inherit] w-[358px]">
        <Score />
        <p className="absolute font-['Sulphur_Point:Bold',sans-serif] leading-[normal] left-0 not-italic right-[22.07%] text-[#504949] text-[20px] text-nowrap top-[calc(50%-28.5px)] tracking-[1px] whitespace-pre">Wrinkle Remover Eye Cream</p>
        <p className="absolute font-['Sulphur_Point:Regular',sans-serif] leading-[normal] left-0 not-italic right-[82.12%] text-[#aa9e9e] text-[12px] text-nowrap top-[calc(50%+3.5px)] tracking-[1px] whitespace-pre">Face Care</p>
        <p className="absolute font-['Sulphur_Point:Bold',sans-serif] leading-[normal] left-0 not-italic right-[79.05%] text-[#2d2d2d] text-[24px] text-nowrap top-[calc(50%+25.5px)] tracking-[1px] whitespace-pre">$135.00</p>
        <p className="absolute font-['Sulphur_Point:Regular',sans-serif] leading-[normal] left-[87.43%] not-italic right-0 text-[#aa9e9e] text-[14px] text-nowrap text-right top-[calc(50%+32.5px)] tracking-[1px] whitespace-pre">200 ml</p>
      </div>
      <div aria-hidden="true" className="absolute border border-black border-solid inset-[-0.5px] pointer-events-none" />
    </div>
  );
}

export default function Card() {
  return (
    <div className="relative shadow-[0px_4px_4px_0px_rgba(0,0,0,0.25)] size-full" data-name="Card">
      <div className="absolute bg-white h-[481px] left-0 rounded-[12px] top-0 w-[386px]" data-name="Rectangle">
        <div aria-hidden="true" className="absolute border border-black border-solid inset-[-0.5px] pointer-events-none rounded-[12.5px] shadow-[0px_2px_48px_0px_rgba(0,0,0,0.04)]" />
      </div>
      <Image />
      <Info />
    </div>
  );
}