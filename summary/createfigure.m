function createfigure(X1, YMatrix1)
%CREATEFIGURE(X1, YMATRIX1)
%  X1:  x ���ݵ�ʸ��
%  YMATRIX1:  y ���ݵľ���

%  �� MATLAB �� 30-Nov-2018 22:37:45 �Զ�����

% ���� figure
figure1 = figure('InvertHardcopy','off','Color',[1 1 1]);

% ���� axes
axes1 = axes('Parent',figure1,'XScale','log',...
    'Position',[0.13 0.11 0.666428571428571 0.815]);
%% ȡ�������е�ע���Ա���������� X ��Χ
% xlim(axes1,[2.07342823394495 11.6597438076369]);
%% ȡ�������е�ע���Ա���������� Y ��Χ
% ylim(axes1,[0.0448250728862973 0.294825072886297]);
%% ȡ�������е�ע���Ա���������� Z ��Χ
% zlim(axes1,[-1 1]);
box(axes1,'on');
hold(axes1,'on');

% ���� ylabel
ylabel({'Recall Rate'},'FontSize',11);

% ���� xlabel
xlabel({'Number of RoI per Image'},'FontSize',11);

% ʹ�� semilogx �ľ������봴������
semilogx1 = semilogx(X1,YMatrix1,'LineWidth',2,'MarkerSize',4,'Color',[0 0 0],'Parent',axes1);
% set(semilogx1(1),'DisplayName','DTS','Marker','v','LineStyle','--');
% set(semilogx1(2),'DisplayName','DTS-H','Marker','v','LineStyle','--');
% set(semilogx1(3),'DisplayName','DTS-S','Marker','v','LineStyle','--');
set(semilogx1(1),'DisplayName','EdgeBox','Marker','o','LineStyle','-');
set(semilogx1(2),'DisplayName','EB+CasFilter','Marker','x','LineStyle','--');
set(semilogx1(3),'DisplayName','EB+CasFilter+V','Marker','>','LineStyle','--');
set(semilogx1(4),'DisplayName','EB+CasFilter+T','Marker','<','LineStyle','-');
set(semilogx1(5),'DisplayName','EB+CasFilter+S','Marker','+','LineStyle','-');
set(semilogx1(6),'DisplayName','EB+CasFilter+V+T','Marker','<','LineStyle',':');
set(semilogx1(7),'DisplayName','EB+CasFilter+V+S','Marker','x','LineStyle','-');
set(semilogx1(8),'DisplayName','EB+CasFilter+T+S','Marker','o','LineStyle','--');
set(semilogx1(9),'DisplayName','EB+CasFilter+V+T+S','Marker','>','LineStyle','-');
set(semilogx1(10),'DisplayName','RPN','Marker','+','LineStyle','--');


% ���� legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.745534553405453 0.10952380952381 0.300662661430501 0.818316740635393],...
    'FontSize',9);

