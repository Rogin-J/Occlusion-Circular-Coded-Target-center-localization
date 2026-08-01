function H = compute_entropy(contour, p, bin_width)

% contour : Nx2 contour points
% p       : candidate center [x,y]
% bin_width : histogram bin width

%% distance calculation
d = sqrt( (contour(:,1)-p(1)).^2 + ...
          (contour(:,2)-p(2)).^2 );

%% histogram construction
d_min = min(d);
d_max = max(d);

edges = d_min:bin_width:(d_max + bin_width);

h = histcounts(d, edges);

%% probability normalization
q = h / sum(h);

%% remove zero bins
q(q == 0) = [];

%% entropy calculation
H = -sum(q .* log(q));

end