function coord_y= coordinate_convert_vid(coord_cell,box_coordinates)
for i=1:size(box_coordinates,1)
    coordinat_best=coord_cell{i};
    box_coordinate=squeeze(box_coordinates(i,:,:));
    coordinat_best_global(:,:,i)=box_coordinate+coordinat_best;
end

for i=1:size(box_coordinates,1)
    for j=1:size(box_coordinates,2)
        coord_y(i,j)= coordinat_best_global(j,2,i);
    end
end
end


