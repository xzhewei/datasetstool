function [err] = eval_roadline(dt_line,gt)
%UNTITLED2 �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
gt_line = center_line(gt);
index = gt_line ~= 0;
diff_line = abs(gt_line - dt_line);
err.avgerr = mean(diff_line(index));
err.stderr = std(diff_line(index));
err.maxerr = max(diff_line(index));
err.minerr = min(diff_line(index));
err.diff_line = diff_line;
err.index = index;
err.gt_line = gt_line;
end

