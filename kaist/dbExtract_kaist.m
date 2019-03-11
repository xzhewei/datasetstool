function dbExtract_kaist( tDir, type, flatten, skip, pth )
% Extract database to directory of images and ground truth text files.
%
% Call 'dbInfo(name)' first to specify the dataset. The format of the
% ground truth text files is the format defined and used in bbGt.m.
%
% USAGE
%  dbExtract( tDir, flatten )
%
% INPUTS
%  tDir     - [] target dir for image data (defaults to dataset dir)
%  flatten  - [0] if true output all images to single directory
%  skip     - [] specify frames to extract (defaults to skip in dbInfo)
%
% OUTPUTS
%
% EXAMPLE
%  dbInfo('InriaTest'); dbExtract;
%
% See also dbInfo, bbGt, vbb
%
% Caltech Pedestrian Dataset     Version 3.2.1
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

[pthl,setIds,vidIds] = dbInfo;
if(nargin<1 || isempty(tDir)), tDir=pthl; end
if(nargin<2 || isempty(flatten)), flatten=0; end
if(nargin<3 || isempty(skip)), [~,~,~,skip]=dbInfo; end
if(nargin<4 || isempty(pth)),  pth=pthl; end
for s=1:length(setIds)
    ticId = ticStatus(['Extract set' num2str(setIds(s)) ':'],0.2,1);
  for v=1:length(vidIds{s})
    % load ground truth
    name=sprintf('set%02d/V%03d',setIds(s),vidIds{s}(v));
    A=vbb('vbbLoadTxt',[pth '/annotations/' name]); n=A.nFrame;
    if(flatten), post=''; else post=[name '/']; end
    if(flatten), f=[name '_']; f(6)='_'; else f=''; end
    fs=cell(1,n); for i=1:n, fs{i}=[f 'I' int2str2(i-1,5)]; end
    % extract images
    td=[tDir '/images/' post]; if(~exist(td,'dir')), mkdir(td); end
    sname = sprintf('set%02d/%s_V%03d',setIds(s),upper(type),vidIds{s}(v));
    sr=seqIo([pth '/videos/' sname '.seq'],'reader'); 
    info=sr.getinfo();
    for i=skip-1:skip:n-1 
      f=[td fs{i+1} '.' info.ext]; if(exist(f,'file')), continue; end
      sr.seek(i); I=sr.getframeb(); f=fopen(f,'w'); fwrite(f,I); fclose(f);
    end; sr.close();
    % extract ground truth
    td=[tDir '/annotations/' post];
    for i=1:n, fs{i}=[fs{i} '.txt']; end
    vbb('vbbToFiles',A,td,fs,skip,skip);
    tocStatus(ticId,v/length(vidIds{s})); 
  end
end

end
