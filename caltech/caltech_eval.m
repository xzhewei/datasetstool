function caltech_eval(res_dir, output_dir, alg_name)
% Copyright (c) 2018, Zhewei Xu
% [xzhewei-at-gmail.com]
% Licensed under The MIT License [see LICENSE for details]
exps = {
  'Reasonable',     [50 inf],  [.65 inf], 0,   .5,  1.25
  'All',            [20 inf],  [.2 inf],  0,   .5,  1.25
  'Scale=large',    [100 inf], [inf inf], 0,   .5,  1.25
  'Scale=near',     [80 inf],  [inf inf], 0,   .5,  1.25
  'Scale=medium',   [30 80],   [inf inf], 0,   .5,  1.25
  'Scale=far',      [20 30],   [inf inf], 0,   .5,  1.25
  'Occ=none',       [50 inf],  [inf inf], 0,   .5,  1.25
  'Occ=partial',    [50 inf],  [.65 1],   0,   .5,  1.25
  'Occ=heavy',      [50 inf],  [.2 .65],  0,   .5,  1.25
  'Ar=all',         [50 inf],  [inf inf], 0,   .5,  1.25
  'Ar=typical',     [50 inf],  [inf inf],  .1, .5,  1.25
  'Ar=atypical',    [50 inf],  [inf inf], -.1, .5,  1.25
  'Overlap=25',     [50 inf],  [.65 inf], 0,   .25, 1.25
  'Overlap=50',     [50 inf],  [.65 inf], 0,   .50, 1.25
  'Overlap=75',     [50 inf],  [.65 inf], 0,   .75, 1.25
  'Expand=100',     [50 inf],  [.65 inf], 0,   .5,  1.00
  'Expand=125',     [50 inf],  [.65 inf], 0,   .5,  1.25
  'Expand=150',     [50 inf],  [.65 inf], 0,   .5,  1.50 };
exps=cell2struct(exps',{'name','hr','vr','ar','overlap','filter'});

dataNames = {'UsaTest','UsaTest_new'};

% remaining parameters and constants
aspectRatio = .41;        % default aspect ratio for all bbs
bnds = [5 5 635 475];     % discard bbs outside this pixel range
plotRoc = 1;              % if true plot ROC else PR curves
plotAlg = 1;              % if true one plot per alg else one plot per exp
plotNum = 15;             % only show best plotNum curves (and VJ and HOG)
samplesMR2 = 10.^(-2:.25:0); % samples for computing area under the curve FPPI=0.
samplesMR4 = 10.^(-4:.25:0); % samples for computing area under the curve
lims = [2e-4 50 .035 1];  % axis limits for ROC plots
bbsShow = 0;              % if true displays sample bbs for each alg/exp
bbsType = 'fp';           % type of bbs to display (fp/tp/fn/dt)

n=1000; clrs=zeros(n,3);
for i=1:n, clrs(i,:)=max(.3,mod([78 121 42]*(i+1),255)/255); end
algs = {  alg_name, 0, clrs(6,:), '-'};
algs=cell2struct(algs',{'name','resize','color','style'});

if ~exist(res_dir, 'dir')
    print(['There is not ' res_dir]);
    return
end

for d=1:length(dataNames), dataName=dataNames{d};
dbInfo(dataName);
output_dir2 = [output_dir '/' dataName];
if (~exist(output_dir2,'dir')), mkdir(output_dir2); end

plotName=[fileparts(mfilename('fullpath')) '/results/' dataName];
if(~exist(plotName,'dir')), mkdir(plotName); end

% load detections and ground truth and evaluate
dts = loadDt( algs, res_dir, output_dir2, aspectRatio );
if strcmp(dataName,'UsaTest_new')
    gts = loadGt_new( exps, plotName, aspectRatio, bnds );
else
    gts = loadGt( exps, output_dir2, aspectRatio, bnds );
end
res = evalAlgs( output_dir2, algs, exps, gts, dts );

% plot curves and bbs
fprintf('MR-2 (FPPI in [%e,%e])\n',samplesMR2(1),samplesMR2(end));
plotExps( res, plotRoc, plotAlg, plotNum, [output_dir2 '-MR2'], ...
  samplesMR2, lims, reshape([algs.color]',3,[])', {algs.style} );
fprintf('MR-4 (FPPI in [%e,%e])\n',samplesMR4(1),samplesMR4(end));
plotExps( res, plotRoc, plotAlg, plotNum, [output_dir2 '-MR4'], ...
  samplesMR4, lims, reshape([algs.color]',3,[])', {algs.style} );
plotBbs( res, output_dir2, bbsShow, bbsType );

end
end

function plotExps( res, plotRoc, plotAlg, plotNum, plotName, ...
  samples, lims, colors, styles )
% Plot all ROC or PR curves.
%
% INPUTS
%  res      - output of evalAlgs
%  plotRoc  - if true plot ROC else PR curves
%  plotAlg  - if true one plot per alg else one plot per exp
%  plotNum  - only show best plotNum curves (and VJ and HOG)
%  plotName - filename for saving plots
%  samples  - samples for computing area under the curve
%  lims     - axis limits for ROC plots
%  colors   - algorithm plot colors
%  styles   - algorithm plot linestyles

% Compute (xs,ys) and score (area under the curve) for every exp/alg
[nGt,nDt]=size(res); xs=cell(nGt,nDt); ys=xs; scores=zeros(nGt,nDt);
for g=1:nGt
  for d=1:nDt
    [xs{g,d},ys{g,d},~,score] = ...
      bbGt('compRoc',res(g,d).gtr,res(g,d).dtr,plotRoc,samples);
    if(plotRoc), ys{g,d}=1-ys{g,d}; score=1-score; end
    if(plotRoc), score=exp(mean(log(score))); else score=mean(score); end
    scores(g,d)=score;
  end
end

% Generate plots
if( plotRoc ), fName=[plotName 'Roc']; else fName=[plotName 'Pr']; end
stra={res(1,:).stra}; stre={res(:,1).stre}; scores1=scores*100; % scores1=round(scores*100);
if( plotAlg ), nPlots=nDt; else nPlots=nGt; end; plotNum=min(plotNum,nDt);
for p=1:nPlots
  % prepare xs1,ys1,lgd1,colors1,styles1,fName1 according to plot type
  if( plotAlg )
    xs1=xs(:,p); ys1=ys(:,p); fName1=[fName stra{p}]; lgd1=stre;
    for g=1:nGt, lgd1{g}=sprintf('%.2f%% %s',scores1(g,p),stre{g}); end
    colors1=uniqueColors(1,max(10,nGt)); styles1=repmat({'-','--'},1,nGt);
    f=fopen([fName1 '.txt'],'w');
    for g=1:nGt
        fprintf(f,'%s %f\n',stre{g},scores(g,p)); 
        fprintf('%s %f\n',stre{g},scores(g,p));
    end
  else
    xs1=xs(p,:); ys1=ys(p,:); fName1=[fName stre{p}]; lgd1=stra;
    for d=1:nDt, lgd1{d}=sprintf('%.2f%% %s',scores1(p,d),stra{d}); end
    kp=[find(strcmp(stra,'VJ')) find(strcmp(stra,'HOG')) 2 1];
    [~,ord]=sort(scores(p,:)); kp=ord==kp(1)|ord==kp(2);
    j=find(cumsum(~kp)>=plotNum-2); kp(1:j(1))=1; ord=fliplr(ord(kp));
    xs1=xs1(ord); ys1=ys1(ord); lgd1=lgd1(ord); colors1=colors(ord,:);
    styles1=styles(ord); f=fopen([fName1 '.txt'],'w');
    for d=1:nDt, fprintf(f,'%s %f\n',stra{d},scores(p,d)); end; fclose(f);
  end
  % plot curves and finalize display
  figure(1); clf; grid on; hold on; n=length(xs1); h=zeros(1,n);
  for i=1:n, h(i)=plot(xs1{i},ys1{i},'Color',colors1(i,:),...
      'LineStyle',styles1{i},'LineWidth',2); end
  if( plotRoc )
    yt=[.05 .1:.1:.5 .64 .8]; ytStr=int2str2(yt*100,2);
    for i=1:length(yt), ytStr{i}=['.' ytStr{i}]; end
    set(gca,'XScale','log','YScale','log',...
      'YTick',[yt 1],'YTickLabel',[ytStr '1'],...
      'XMinorGrid','off','XMinorTic','off',...
      'YMinorGrid','off','YMinorTic','off');
    xlabel('false positives per image','FontSize',14);
    ylabel('miss rate','FontSize',14); axis(lims);
  else
    x=1; for i=1:n, x=max(x,max(xs1{i})); end, x=min(x-mod(x,.1),1.0);
    y=.8; for i=1:n, y=min(y,min(ys1{i})); end, y=max(y-mod(y,.1),.01);
    xlim([0, x]); ylim([y, 1]); set(gca,'xtick',0:.1:1);
    xlabel('Recall','FontSize',14); ylabel('Precision','FontSize',14);
  end
  if(~isempty(lgd1)), legend(h,lgd1,'Location','sw','FontSize',11); end
  % save figure to disk (uncomment pdfcrop commands to automatically crop)
  savefig(fName1,1,'pdf','-r300','-fonts'); %close(1);
  if(0), setenv('PATH',[getenv('PATH') ':/usr/texbin/']); end
  if(0), system(['pdfcrop -margins ''-30 -20 -50 -10 '' ' ...
      fName1 '.pdf ' fName1 '.pdf']); end
end

end

function plotBbs( res, plotName, pPage, type )
% This function plots sample fp/tp/fn bbs for given algs/exps
if(pPage==0), return; end; [nGt,nDt]=size(res);
% construct set/vid/frame index for each image
[~,setIds,vidIds,skip]=dbInfo;
k=length(res(1).gtr); is=zeros(k,3); k=0;
for s=1:length(setIds)
  for v=1:length(vidIds{s})
    A=loadVbb(s,v); s1=setIds(s); v1=vidIds{s}(v);
    for f=skip-1:skip:A.nFrame-1, k=k+1; is(k,:)=[s1 v1 f]; end
  end
end
for g=1:nGt
  for d=1:nDt
    % augment each bb with set/video/frame index and flatten
    dtr=res(g,d).dtr; gtr=res(g,d).gtr;
    for i=1:k
      dtr{i}(:,7)=is(i,1); dtr{i}(:,8)=is(i,2); dtr{i}(:,9)=is(i,3);
      gtr{i}(:,6)=is(i,1); gtr{i}(:,7)=is(i,2); gtr{i}(:,8)=is(i,3);
      dtr{i}=dtr{i}'; gtr{i}=gtr{i}';
    end
    dtr=[dtr{:}]'; dtr=dtr(dtr(:,6)~=-1,:);
    gtr=[gtr{:}]'; gtr=gtr(gtr(:,5)~=-1,:);
    % get bb, ind, bbo, and indo according to type
    if( strcmp(type,'fn') )
      keep=gtr(:,5)==0; ord=randperm(sum(keep));
      bbCol='r'; bboCol='y'; bbLst='-'; bboLst='--';
      bb=gtr(:,1:4); ind=gtr(:,6:8); bbo=dtr(:,1:6); indo=dtr(:,7:9);
    else
      switch type
        case 'dt', bbCol='y'; keep=dtr(:,6)>=0;
        case 'fp', bbCol='r'; keep=dtr(:,6)==0;
        case 'tp', bbCol='y'; keep=dtr(:,6)==1;
      end
      [~,ord]=sort(dtr(keep,5),'descend');
      bboCol='g'; bbLst='--'; bboLst='-';
      bb=dtr(:,1:6); ind=dtr(:,7:9); bbo=gtr(:,1:4); indo=gtr(:,6:8);
    end
    % prepare and display
    n=sum(keep); bbo1=cell(1,n); O=ones(1,size(indo,1));
    ind=ind(keep,:); bb=bb(keep,:); ind=ind(ord,:); bb=bb(ord,:);
    for f=1:n, bbo1{f}=bbo(all(indo==ind(O*f,:),2),:); end
    f=[plotName res(g,d).stre res(g,d).stra '-' type];
    plotBbSheet( bb, ind, bbo1,'fName',f,'pPage',pPage,'bbCol',bbCol,...
      'bbLst',bbLst,'bboCol',bboCol,'bboLst',bboLst );
  end
end
end

function plotBbSheet( bb, ind, bbo, varargin )
% Draw sheet of bbs.
%
% USAGE
%  plotBbSheet( R, varargin )
%
% INPUTS
%  bb       - [nx4] bbs to display
%  ind      - [nx3] the set/video/image number for each bb
%  bbo      - {nx1} cell of other bbs for each image (optional)
%  varargin - prm struct or name/value list w following fields:
%   .fName    - ['REQ'] base file to save to
%   .pPage    - [1] num pages
%   .mRows    - [5] num rows / page
%   .nCols    - [9] num cols / page
%   .scale    - [2] size of image region to crop relative to bb
%   .siz0     - [100 50] target size of each bb
%   .pad      - [4] amount of space between cells
%   .bbCol    - ['g'] bb color
%   .bbLst    - ['-'] bb LineStyle
%   .bboCol   - ['r'] bbo color
%   .bboLst   - ['--'] bbo LineStyle
dfs={'fName','REQ', 'pPage',1, 'mRows',5, 'nCols',9, 'scale',1.5, ...
  'siz0',[100 50], 'pad',8, 'bbCol','g', 'bbLst','-', ...
  'bboCol','r', 'bboLst','--' };
[fName,pPage,mRows,nCols,scale,siz0,pad,bbCol,bbLst, ...
  bboCol,bboLst] = getPrmDflt(varargin,dfs);
n=size(ind,1); indAll=ind; bbAll=bb; bboAll=bbo;
for page=1:min(pPage,ceil(n/mRows/nCols))
  Is = zeros(siz0(1)*scale,siz0(2)*scale,3,mRows*nCols,'uint8');
  bbN=[]; bboN=[]; labels=repmat({''},1,mRows*nCols);
  for f=1:mRows*nCols
    % get fp bb (bb), double size (bb2), and other bbs (bbo)
    f0=f+(page-1)*mRows*nCols; if(f0>n), break, end
    [col,row]=ind2sub([nCols mRows],f);
    ind=indAll(f0,:); bb=bbAll(f0,:); bbo=bboAll{f0};
    hr=siz0(1)/bb(4); wr=siz0(2)/bb(3); mr=min(hr,wr);
    bb2 = round(bbApply('resize',bb,scale*hr/mr,scale*wr/mr));
    bbo=bbApply('intersect',bbo,bb2); bbo=bbo(bbApply('area',bbo)>0,:);
    labels{f}=sprintf('%i/%i/%i',ind(1),ind(2),ind(3));
    % normalize bb and bbo for siz0*scale region, then shift
    bb=bbApply('shift',bb,bb2(1),bb2(2)); bb(:,1:4)=bb(:,1:4)*mr;
    bbo=bbApply('shift',bbo,bb2(1),bb2(2)); bbo(:,1:4)=bbo(:,1:4)*mr;
    xdel=-pad*scale-(siz0(2)+pad*2)*scale*(col-1);
    ydel=-pad*scale-(siz0(1)+pad*2)*scale*(row-1);
    bb=bbApply('shift',bb,xdel,ydel); bbN=[bbN; bb]; %#ok<AGROW>
    bbo=bbApply('shift',bbo,xdel,ydel); bboN=[bboN; bbo]; %#ok<AGROW>
    % load and crop image region
    sr=seqIo(sprintf('%s/videos/set%02i/V%03i',dbInfo,ind(1),ind(2)),'r');
    sr.seek(ind(3)); I=sr.getframe(); sr.close();
    I=bbApply('crop',I,bb2,'replicate');
    I=uint8(imResample(double(I{1}),siz0*scale));
    Is(:,:,:,f)=I;
  end
  % now plot all and save
  prm=struct('hasChn',1,'padAmt',pad*2*scale,'padEl',0,'mm',mRows,...
    'showLines',0,'labels',{labels});
  h=figureResized(.9,1); clf; montage2(Is,prm); hold on;
  bbApply('draw',bbN,bbCol,2,bbLst); bbApply('draw',bboN,bboCol,2,bboLst);
  savefig([fName int2str2(page-1,2)],h,'png','-r200','-fonts'); close(h);
  if(0), save([fName int2str2(page-1,2) '.mat'],'Is'); end
end
end

function res = evalAlgs( output_dir, algs, exps, gts, dts )
% Evaluate every algorithm on each experiment
%
% OUTPUTS
%  res    - nGt x nDt cell of all evaluations, each with fields
%   .stra   - string identifying algorithm
%   .stre   - string identifying experiment
%   .gtr    - [n x 1] gt result bbs for each frame [x y w h match]
%   .dtr    - [n x 1] dt result bbs for each frame [x y w h score match]
fprintf('Evaluating: %s\n',output_dir); nGt=length(gts); nDt=length(dts);
res=repmat(struct('stra',[],'stre',[],'gtr',[],'dtr',[]),nGt,nDt);
for g=1:nGt
  for d=1:nDt
    gt=gts{g}; dt=dts{d}; n=length(gt); assert(length(dt)==n);
    stra=algs(d).name; stre=exps(g).name;
    fName = [output_dir '/ev-' [stre '-' stra] '.mat'];
    if(exist(fName,'file')), R=load(fName); res(g,d)=R.R; continue; end
    fprintf('\tExp %i/%i, Alg %i/%i: %s/%s\n',g,nGt,d,nDt,stre,stra);
    hr = exps(g).hr.*[1/exps(g).filter exps(g).filter];
    for f=1:n, 
        if (size(dt{f},1)>0)
            bb=dt{f}; dt{f}=bb(bb(:,4)>=hr(1) & bb(:,4)<hr(2),:); 
        end
    end
    [gtr,dtr] = bbGt('evalRes',gt,dt,exps(g).overlap);
    R=struct('stra',stra,'stre',stre,'gtr',{gtr},'dtr',{dtr});
    res(g,d)=R; save(fName,'R');
  end
end
end

function A = loadVbb( s, v )
% Load given annotation (caches AS for speed).
persistent AS pth sIds vIds; [pth1,sIds1,vIds1]=dbInfo;
if(~strcmp(pth,pth1) || ~isequal(sIds,sIds1) || ~isequal(vIds,vIds1))
  [pth,sIds,vIds]=dbInfo; AS=cell(length(sIds),1e3); end
A=AS{s,v}; if(~isempty(A)), return; end
fName=@(s,v) sprintf('%s/annotations/set%02i/V%03i',pth,s,v);
A=vbb('vbbLoad',fName(sIds(s),vIds{s}(v))); AS{s,v}=A;
end

function gts = loadGt( exps, output_dir, aspectRatio, bnds )
% Load ground truth of all experiments for all frames.
fprintf('Loading ground truth: %s\n', output_dir);
nExp=length(exps); gts=cell(1,nExp);
[~,setIds,vidIds,skip] = dbInfo;
for i=1:nExp
  gName = [output_dir '/gt-' exps(i).name '.mat'];
  if(exist(gName,'file')), gt=load(gName); gts{i}=gt.gt; continue; end
  fprintf('\tExperiment #%d: %s\n', i, exps(i).name);
  gt=cell(1,100000); k=0; lbls={'person','person?','people','ignore'};
  filterGt = @(lbl,bb,bbv) filterGtFun(lbl,bb,bbv,...
    exps(i).hr,exps(i).vr,exps(i).ar,bnds,aspectRatio);
  for s=1:length(setIds)
    for v=1:length(vidIds{s})
      A = loadVbb(s,v);
      for f=skip-1:skip:A.nFrame-1
        bb = vbb('frameAnn',A,f+1,lbls,filterGt); ids=bb(:,5)~=1;
        bb(ids,:)=bbApply('resize',bb(ids,:),1,0,aspectRatio);
        k=k+1; gt{k}=bb;
      end
    end
  end
  gt=gt(1:k); gts{i}=gt; save(gName,'gt','-v6');
end

  function p = filterGtFun( lbl, bb, bbv, hr, vr, ar, bnds, aspectRatio )
    p=strcmp(lbl,'person'); h=bb(4); p=p & (h>=hr(1) & h<hr(2));
    if(all(bbv==0)), vf=inf; else vf=bbv(3).*bbv(4)./(bb(3)*bb(4)); end
    p=p & vf>=vr(1) & vf<=vr(2);
    if(ar~=0), p=p & sign(ar)*abs(bb(3)./bb(4)-aspectRatio)<ar; end
    p = p & bb(1)>=bnds(1) & (bb(1)+bb(3)<=bnds(3));
    p = p & bb(2)>=bnds(2) & (bb(2)+bb(4)<=bnds(4));
  end
end

function gts = loadGt_new( exps, plotName, aspectRatio, bnds )
  persistent pth; pth1=dbInfo;
  if(~strcmp(pth,pth1)), pth=dbInfo; end
  fprintf('Loading ground truth: %s\n',plotName);
  nExp=length(exps); gts=cell(1,nExp);
  for i=1:nExp
    gName = [plotName '/gt-new-' exps(i).name '.mat'];
    if(exist(gName,'file')), gt=load(gName); gts{i}=gt.gt; continue; end
    fprintf('\tExperiment #%d: %s\n', i, exps(i).name);
    if (exps(i).ar~=0) 
        ar=exps(i).ar; 
        arRng=[-ar/sign(ar)+aspectRatio,ar/sign(ar)+aspectRatio];
    else
        arRng=[];
    end
    pLoad = {'lbls',{'person','person?','people','ignore'},...
           'hRng',exps(i).hr,'vRng',exps(i).vr,'arRng', arRng,...
           'xRng',[bnds(1) bnds(3)],'yRng',[bnds(2) bnds(4)]};
    [gt,~] = bbGt('loadAll',[pth '\Caltech_new_annotations\test_1x_new'],{},pLoad);
    for k=1:length(gt)
      bb = gt{k}; ids = bb(:,5)~=1;
      bb(ids,:)=bbApply('resize',bb(ids,:),1,0,aspectRatio);
      gt{k} = bb;
    end
    gts{i}=gt; save(gName,'gt','-v6');
  end  
end

function dts = loadDt( algs, res_dir, output_dir, aspectRatio )
% Load detections of all algorithm for all frames.
fprintf('Loading detections: %s\n',res_dir);
nAlg=length(algs); dts=cell(1,nAlg);
[~,setIds,vidIds,skip] = dbInfo;
for i=1:nAlg
  aName = [output_dir '/dt-' algs(i).name '.mat'];
  if(exist(aName,'file')), dt=load(aName); dts{i}=dt.dt; continue; end
  fprintf('\tAlgorithm #%d: %s\n', i, algs(i).name);
  dt=cell(1,100000); k=0; aDir=res_dir;
  if(algs(i).resize), resize=100/128; else resize=1; end
  for s=1:length(setIds), s1=setIds(s);
    for v=1:length(vidIds{s}), v1=vidIds{s}(v);
      A=loadVbb(s,v); frames=skip-1:skip:A.nFrame-1;
      vName=sprintf('%s/set%02d/V%03d',aDir,s1,v1);
      if(~exist([vName '.txt'],'file'))
        % consolidate bbs for video into single text file
        bbs=cell(length(frames),1);
        for f=1:length(frames)
          fName = sprintf('%s/I%05d.txt',vName,frames(f));
          if(~exist(fName,'file')), error(['file not found:' fName]); end
          bb=load(fName,'-ascii'); if(isempty(bb)), bb=zeros(0,5); end
          if(size(bb,2)~=5), error('incorrect dimensions'); end
          bbs{f}=[ones(size(bb,1),1)*(frames(f)+1) bb];
        end
        for f=frames, delete(sprintf('%s/I%05d.txt',vName,f)); end
        bbs=cell2mat(bbs); dlmwrite([vName '.txt'],bbs); rmdir(vName,'s');
      end
      bbs=load([vName '.txt'],'-ascii');
      for f=frames, 
        if(size(bbs,1)==0)
            k=k+1;
        else
            bb=bbs(bbs(:,1)==f+1,2:6);
            bb=bbApply('resize',bb,resize,0,aspectRatio); k=k+1; dt{k}=bb;
        end
      end
    end
  end
  dt=dt(1:k); dts{i}=dt; save(aName,'dt','-v6');
end
end