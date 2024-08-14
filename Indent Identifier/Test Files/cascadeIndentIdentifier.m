close all;  % Close all figures (except those of imtool.)

%add functions/images to path
functionname='cascadeIndentIdentifier.m'; functiondir=which(functionname);
functiondir=functiondir(1:end-length(functionname));
addpath([functiondir 'Functions'])
addpath([functiondir 'Test Images'])
addpath([functiondir 'Training Data'])

detector = vision.CascadeObjectDetector('indentDetector_20_025.xml');%initialize machine vision
I = imread('testImage9.jpg');

bbox = step(detector,I);%detect all indents and put positions into matrix of boxes

J = insertShape(I,'rectangle',bbox, 'LineWidth', 2);%draw all bounding boxes
figure;imshow(J)

%process individual objects
H = height(bbox);

for i = 1:1:height(bbox)
    %roi = images.roi.Rectangle(gca, 'Position', bbox(i,1:4), 'StripeColor', 'b');%draw roi
    C = imcrop(I,bbox(i,1:4));
    G = rgb2gray(C);
    B = imbinarize(G);
    E = edge(B, 'canny');%detect edges
    EF = imfill(E, 'holes');
    %figure; imshow(E);%debugging    
    CC = bwconncomp(EF); %// Find connected components.
    BWF = zeros(size(EF)); %// Store final image
    initialArea = 0;
    index = 0;
    hold on
    for k = 1:CC.NumObjects %// Loop through each object and plot it in white. This is where you can create individual figures for each object.
        BWT = zeros(size(EF)); %// Store temp image
        PixId = CC.PixelIdxList{k}; %//simpler to understand
        if size(PixId,1) ==1 %// If only one row, don't consider.        
            continue
        end
        BWT(PixId) = 255;
        area = bwarea(BWT);
        if area > initialArea
            BWF = BWT;
            index = k;
            initialArea = area;
        end
    end
    
    if initialArea < 1000
        continue
    end%disregard if area too small
    
    %EB = imclearborder(EF,4);%remove objects touching border
    %seD = strel('diamond',1);BWF = imerode(BWF,seD);%smoothen/"erode" image  

    
    %search image for diagonal
    %this loop will look through all points of the indent and find the
    %leftmost and righmost points
    dimensions = size(BWF);%1-dimensional array [rows,columns]

    XL = dimensions(2);
    YL = dimensions(1);
    XR = 0;
    YR = 0;
    for x = 1:1:dimensions(2)
        for y = 1:1:dimensions(1)
            if BWF(y,x)==255%check if pixel is part of indent
                if x < XL
                    XL = x;
                    YL = y;
                end
                if x > XR
                    XR = x;
                    YR = y;
                end
            end
        end
    end
    
    BWoutline = bwperim(BWF);
    Segout = C;
    Segout(BWoutline) = 255;
    figure;imshow(Segout);axis on;hold on;line([XL,XR],[YL,YR],'LineWidth', 2, 'Color', 'red');
    L = sqrt((XR-XL)^2+(YR-YL)^2)%calculate indent length in pixels

    
end

release(detector)