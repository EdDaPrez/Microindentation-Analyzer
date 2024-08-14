step_size = -0.01;
IMG = imread("DSC_7831.JPG");
gray = rgb2gray(IMG);
edges_sovel = edge(gray, 'sobel', step_size);
imshow(imfill(edges_sovel, 'holes')); 


    %search image for diagonal
    %this loop will look through all points of the indent and find the
    %leftmost and righmost points
    XL = 1000000000;
    YL = 1000000000;
    XR = 0;
    YR = 0;
    dimensions = size(BWF);%1-dimensional array [rows,columns]
    for x = 1:1:dimensions(1)
        for y = 1:1:dimensions(2)
            BWF(x,y)
            if BWF(x,y)==255%check if pixel is part of indent
                if x < XL
                    XL = x;
                    YL = y;
                end
                if x > XR;
                    XR = x;
                    YR = y;
                end
            end
        end
    end
    
    XL
    YL
    XR
    YR
