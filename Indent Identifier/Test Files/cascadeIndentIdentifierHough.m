close all;  % Close all figures (except those of imtool.)
clearvars; %clear variables

%add functions/images to path
functionname='cascadeIndentIdentifier.m'; functiondir=which(functionname);
functiondir=functiondir(1:end-length(functionname));
addpath([functiondir 'Functions'])
addpath([functiondir 'Test Images'])

angleGreaterThan = 20;
angleLessThan = 40;
numLines = 4;

detector = vision.CascadeObjectDetector('indentDetector_20_025.xml');%initialize machine vision
I = imread('testImage1.jpg');
bbox = step(detector,I);%detect all indents and put positions into matrix of boxes
J = insertShape(I,'rectangle',bbox, 'LineWidth', 2);%draw all bounding boxes
figure;imshow(J)

%process individual objects
allLines.x = [];
allLines.y = [];
verticalLine.x = [];
verticalLine.y = [];
for i = 1:1:height(bbox)
    %roi = images.roi.Rectangle(gca, 'Position', bbox(i,1:4), 'StripeColor', 'b');%draw roi
    C = imcrop(I,bbox(i,1:4));
    G = rgb2gray(C);
    B = imbinarize(G);
    E = edge(B, 'sobel');%detect edges
    %figure; imshow(E);%debugging

    [H,theta,rho] = hough(E);
    
    %shows hough transforms
    figure
    imshow(imadjust(rescale(H)),[],...
           'XData',theta,...
           'YData',rho,...
           'InitialMagnification','fit');
    xlabel('\theta (degrees)')
    ylabel('\rho')
    axis on
    axis normal 
    hold on
    colormap(gca,hot)
    
    exclude = [];
    while true %keep going until no more of the same line found twice
        clear intersect;
        clear allLines;
        clear verticalLine;
        
        intersect.x = [];
        intersect.y = [];
        numPeaks = numLines + length(exclude);
        P = houghpeaks(H,numPeaks,'threshold',ceil(0.3*max(H(:))));%choose # of points
        x = theta(P(:,2));
        y = rho(P(:,1));
        %plot(x,y,'s','color','black');
        lines = houghlines(E,theta,rho,P,'FillGap',1000,'MinLength',8);
        for k = 1:1:length(exclude)
            lines(exclude(k)) = [];
        end
        for k = 1:1:length(lines)
            pto1 = lines(k).point1;  
            pto2 = lines(k).point2;
            % A vector along the ray from pto1 to pto2...
            V1 = pto2 - pto1;
            V2 = pto1 - pto2;        
            % The distance between the points would be:
            %   dist12 = norm(V);
            % but there is no need to compute it.
            % which will be extended (by 200% in this case) here
            factor_distance = 3;
            % Extend the ray
            pext1 = pto1 + V1*factor_distance;
            pext2 = pto2 + V2*factor_distance;
            
            allLines(k).x = [pext1(1) pext2(1)];
            allLines(k).y = [pext1(2) pext2(2)];
        end
       
        %find intersections
        intersections = 0;
        currentExclusions = 0;
        stopLooking = false;
        for k = 1:1:(length(allLines)-1)
            for n = (k + 1):1:length(allLines)
                [xi, yi] = linexline(allLines(k).x, allLines(k).y, allLines(n).x, allLines(n).y, 0);%last parameter 1 to plot intersections
                if(~isnan(xi))
                    intersect(intersections + 1).x = xi;
                    intersect(intersections + 1).y = yi;
                    intersections = intersections + 1;
                    angleValue = abs(lines(k).theta - lines(n).theta);
                    if angleValue >= 90
                        angleValue = 180-angleValue;
                    end
                    angleValue = angleValue*2
                    if angleValue <= angleGreaterThan || angleValue >= angleLessThan
                        exclude(end + 1) = n;
                        currentExclusions = currentExclusions + 1;
                        stopLooking = true;
                        break;
                    end
                end
            end
            if stopLooking == true
                break;
            end
        end
        if currentExclusions == 0
            break;
        end
    end
    %filter unwanted indents
    %insert any filter conditions after if statement
    if intersections ~= 4
        continue
    else
        figure, imshow(C), hold on
        %plot lines
        for k = 1:1:length(allLines)
            plot(allLines(k).x, allLines(k).y, 'r-', 'LineWidth', 2)
        end
        %plot intersections
        for k = 1:1:length(intersect)
            plot(intersect(k).x,intersect(k).y, 'ob');
        end  
        %search image for diagonals
        %this loop will look through all points of the indent and find the
        %leftmost and righmost points
        dimensions = size(E);%1-dimensional array [rows,columns]
        leftPoint = [dimensions(2) dimensions(1)];
        rightPoint = [0 0];
        for k = 1:1:length(intersect)
            if intersect(k).x < leftPoint(1)
                leftPoint = [intersect(k).x intersect(k).y];
                n1 = k;
            end
            if intersect(k).x > rightPoint(1)
                rightPoint = [intersect(k).x intersect(k).y];
                n2 = k;
            end
        end
        nonCounter = 1;
        for k = 1:1:length(intersect)
           if (k ~= n1) && (k ~= n2)
                verticalLine(nonCounter).x = intersect(k).x;
                verticalLine(nonCounter).y = intersect(k).y;
                nonCounter = nonCounter + 1;
           end
        end
        
        line([leftPoint(1), rightPoint(1)], [leftPoint(2), rightPoint(2)],'LineWidth', 2, 'Color', 'blue');
        line([verticalLine(1).x, verticalLine(2).x], [verticalLine(1).y, verticalLine(2).y],'LineWidth', 2, 'Color', 'blue');
        L1 = sqrt((rightPoint(1)-leftPoint(1))^2+(rightPoint(2)-leftPoint(2))^2);%calculate indent length in pixels
    end
end
release(detector);