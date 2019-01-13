%%Automated Image Analysis Program for LAMP Reaction


%DISPLAY INSTRUCTIONS TO USER
fprintf('Select images in order of time. Results will be more accurate if');
fprintf(newline);
fprintf('images known to not contain a reaction droplet are not included.');
fprintf(newline);
fprintf(newline);
%pause(4); %pause before displaying files 

%USER SELECTS IMAGES TO BE ANALYZED
[WhichFile, PathName] = uigetfile({'*.jpg;*.tif;*.png'},'Select images (in order of time)', 'MultiSelect', 'on'); 
if isequal(WhichFile, 0) %if user hits cancel, exit program
   disp('Goodbye')
   return; 
end
WhichFile = cellstr(WhichFile);  %allows user to select only one image if desired

%BEGIN IMAGE ANALYSIS
heighttrend = zeros(); %creates array for height values
true_basetrend = zeros(); %creates array for baselength values

%PREPARE TO SAVE THINGS
%destdirectory = '/Users/jtsosnowski/Documents/MATLAB';
%Get the name of the file that the user wants to save.
%Note, if you're saving an image you can use imsave() instead of uiputfile().
%startingFolder = userpath;
%defaultFileName = fullfile(startingFolder, '*.*');
%[baseFileName, folder] = uiputfile(defaultFileName, 'Specify a file');
%if baseFileName == 0
    %user hit cancel
    %return;
%end
%fullFileName = fullfile(folder, baseFileName);

for i=1:length(WhichFile) %iterates through the list of files that user selects
    height = 0; %default height is zero (if no bubble detected)
    
    %READ IN AND EDIT IMAGE
    original = imread([PathName, WhichFile{i}]); %read in original file
    %figure(1); imagesc(original); colormap('gray'); title('Original Image');
    red = original(:,:,1); % Takes only blue channel - better contrast & 
    %eliminates random colored pixels after binarization;
    %Note that for our images it doesn't seem to matter which color channel is
    %selected as long as one is selected
    %figure(2); imagesc(I_blue); colormap('gray'); title('Blue Channel');
    
    %cropped = imcrop(zoomed, [1000 1000 600 500]); %FOR NTC, zoomed %array arguments are different depending on software
    %cropped = imcrop(blue, [300 210 150 46]); %FOR E. COLI TARGET, not zoomed
    %cropped = imcrop(blue, [150 180 150 60]); %FOR STAPH TARGET, not zoomed
    %cropped = imcrop(blue, [225 215 95 60]); %FOR STAPH TARGET 11/6, not zoomed
    %cropped = imcrop(blue, [184 188 102 61]); %FOR E. COLI TARGET 2/23, not zoomed
    %cropped = imcrop(blue, [420 201 98 53]); %FOR E. COLI TARGET 2/23, not zoomed

    %figure(4); imagesc(cropped); colormap('gray'); title('Cropped');
    if i==1 
       cropped = imcrop(red); %opens interactive cropping tool
       data = clipboard('paste'); %when user selects to copy position it is pasted to clipboard as character array
       data(regexp(data, '[[]]')) = []; %brakets are removed from array
       position = split(data, ' '); %position is split into 4 individual numbers (array of arrays)
       a = str2double(position(1)); %starting index in x
       b = str2double(position(2)); %starting index in y
       c = str2double(position(3)); %distance in x
       d = str2double(position(4)); %distance in y
       cropped = imcrop(red, [a b c d]); %image cropped according to user input
       %figure(6); imagesc(cropped); colormap('gray'); title('cropped original');
    else
       cropped = imcrop(red, [a b c d]); %image cropped according to user input for first image
        %figure(6); imagesc(cropped); colormap('gray'); title('cropped original');
    end
    
    level = graythresh(cropped); %find the optimum threshold level for binarization
    
    bw = imbinarize(cropped, level); %Makes the ref image black and white according to previously determined threshold level
    %figure(3); imagesc(bw); colormap('gray'); title('Binarized (B&W)');
    %Note: NOT using 'adaptive' flag because this made images worse overall

    filled = imfill(bw, 'holes');  %fills in black pixels (holes) on white bubble
    %figure(5); imagesc(filled); colormap('gray'); title('Fill in Droplet Holes');
    bwinvert = imcomplement(filled); %Inverts image so the bubble is now black with white background
    %figure(6); imagesc(bwinvert); colormap('gray'); title('B&W Inverted');
    filled_2 = imfill(bwinvert, 'holes'); %fills in black pixels (holes) on white background
    %figure(7); imagesc(filled_2); colormap('gray'); title('Fill in Background Holes');
    final = imcomplement(filled_2); %re-invert so white pixels will be considered part of droplet 
    %figure(8); imagesc(final); colormap('gray'); title('FINAL IMAGE-TO BE ANALYZED');
    
    %SAVE IMAGES TO TIME/DATE STAMPED FOLDER
    %destdirectory = '/Users/jtsosnowski/Documents/MATLAB';
    %newFolder = mkdir (datestr(now, 'dd-MMM-yyyy HH-MM'));
    %thisimage = sprintf('image%d.png', i);
    %fulldestination = fullfile(destdirectory, newFolder, thisimage);
    %imwrite(final, fulldestination);  
    
    %SAVE IMAGE
    %name = strcat('image', i, '.png');
    %imagePath = fullFile(fullFileName, name);
    %save(imagePath, final);
    %i=i+1; %continue to next image
    
    figure(i); imagesc(final); colormap('gray'); title('FINAL IMAG - TO BE ANALYZED');
    
    %DETERMINE IF IMAGE CONTAINS REACTION BUBBLE
    %[B,L,N] = bwboundaries(final); %to find boundary of bubble
    %stats=  regionprops(L,'Area','Perimeter');
    %Perimeter = cat(1,stats.Perimeter);
    %Area = cat(1,stats.Area);
    %CircleMetric = (Perimeter.^2)./(4*pi*Area);  %circularity metric
    %hasDroplet = (CircleMetric < 5); %bubble will be considered present if circularity metric is less than 5
    %disp(CircleMetric);
    
    %FINDING BUBBLE HEIGHT
        [row,column,color] = size(final); %determine size of array
        start_point = zeros(); %start points will be white pixels
        stop_point = zeros(); %stop points will be black pixels
        baselength=0;
        start_point(i) = 1;
        foundDrop = 'n';
        stop_point(i) = 1;
        true_baselength = 0;
        unlikely_problem = 'n';
        while foundDrop == 'n'
    %DETERMINE PIXEL VALUES AT BOTTOM ROW OF IMAGE
            for col = stop_point(i):size(final,2) %iterate through columns, beginning where you left off previously
                grayLevel=final(row,col);
                if grayLevel==1 %if white pixel detected
                    baselength=baselength+1; %count each white pixel
                    if start_point(i)==1 %if a start point has not yet been detected, or the start point has been reset previously
                        start_point(i)=col; %This will set the start point to the current column
                        fprintf("Found a new startpoint");
                        fprintf(newline);
                    end
                    if col == column %if this is the last column and there's still white pixels
                        stop_point(i) = col; %the stop point is set to this last column
                        fprintf("You may need to adjust the crop window next time");
                        fprintf(newline);
                        break;
                    end
                else %if black pixel detected
                    if start_point(i) > 1 %if a start point has been detected/has not been reset to zero previously
                        stop_point(i) = col; %note where stopped counting, this is where you will start counting in next iteration
                        break;
                    else
                        continue;
                    end
                end
            end
            if stop_point(i) > 1 % if a stop point has been identified
    %SET THE THRESHOLD FOR THE BASE LENGTH OF THE DROPLET ON THE FIRST IMAGE OF THE DATA SET
                if i==1 %first image
                    %On the first image, the baselength is likely to be the
                    %largest length of white pixels
                    
                    if baselength > true_baselength %if the current potential baselength measured is greater than the last one
                        true_baselength = baselength; %save this baselength as the true baselength in case this is the true baselength
                        if col==column %if done scanning image
                            threshold = true_baselength; %set the threshold!!
                            firstcol = start_point(i); %set first column of baselength to the start point
                            foundDrop = 'y';
                        elseif col < column %if not done scanning the image
                            baselength = 0; %set baselength to zero
                            firstcol = start_point(i); %save start point as first column of baselength in case this is the first column
                            start_point(i) = 1; %reset start point
                            foundDrop = 'n';
                        end
                    elseif baselength < true_baselength %if the current potential baselength measured is less than the last one
                        %do NOT reset true_baselength or firstcol
                        if col==column %if done scanning image
                            threshold = true_baselength; %set the threshold to whatever the last baselength was!!
                            foundDrop = 'y';
                        elseif col < column %if not done scanning the image
                            baselength = 0; %set baselength to zero
                            start_point(i) = 1; %reset start point
                            foundDrop = 'n';
                        end
                    else %if the current potential baselength measured is equal to the last one
                        fprintf("There are two equally likely objects that are the droplet in this image set, please re-crop");
                        fprintf(newline);
                        unlikely_problem = 'y'; %this will later stop the program from continuing to analyze images
                        break;
                    end
                end
    %APPLY THRESHOLD TO THE REMAINDER OF IMAGES IN THE DATA SET
                if i>1

                if baselength >= threshold - 5 %if the current potential baselength measured is greater than/equal to (5 below threshold)
                    true_baselength = baselength; %save this baselength as the true baselength in case this is the true baselength
                    if col==column %if done scanning image
                        firstcol = start_point(i); %set first column of baselength to the start point
                        foundDrop = 'y';
                    elseif col < column %if not done scanning the image
                        baselength = 0; %set baselength to zero
                        firstcol = start_point(i); %save start point as first column of baselength in case this is the first column
                        start_point(i) = 1; %reset start point
                        foundDrop = 'n';
                    end
                else  %if the current potential baselength measured is less than (5 below threshold)
                    %do NOT reset true_baselength or firstcol
                    if col==column %if done scanning image
                        foundDrop = 'y';
                    elseif col < column %if not done scanning the image
                        baselength = 0; %set baselength to zero
                        start_point(i) = 1; %reset start point
                        foundDrop = 'n';
                    end
                end
                end
            end
        end
    
%                 if i>1
%                     if baselength < (threshold - 5) %if the potential baselength is too short to be the true baselength
%                         %fprintf("found false baselength");
%                         %fprintf(newline);
%                         baselength = 0; %set baselength to zero
%                         start_point(i) = 0; %set firstcol to zero
%                         foundDrop = 'n'; %start count over from stoppoint
%                     else
%                         true_baselength = baselength;
%                         foundDrop = 'y'; %otherwise accept the baselength as descriptive of the droplet
%                     end
%                 end
%             end
%         end
            
        if mod(true_baselength,2)==0 %if baseline is even number of pixels
            centerlength= true_baselength/2; %center is defined as the pixel with value half that of baseline 
            %(although the true center would be in between this pixel and the next, we cannot
            %iterate through a column this way)
        else %if the baseline is an odd number of pixels
            centerlength = (true_baselength/2) + 0.5; %half of the baseline value will not be a whole pixel; 
            %adding 0.5 corrects this and also gives the pixel column which is truly the 
            %center of the bubble  
        end
        center = firstcol+centerlength; %define center as pixel of distance centerlength from firstcol (edge of bubble)

        for r = 1:size(final,1) %iterate through all rows...
            grayLevel=final(r,center);
            if grayLevel==1
                height=height+1; %...and add up the white pixels to determine bubble height
            else
                continue;
            end
        end

        heighttrend(i) = height; %add each height value to bubbletrend function
        true_basetrend(i) = true_baselength; %if bubble detected then add its baselength to this function
        if unlikely_problem == 'y' %if two potential droplets are identified, do not proceed through data set
            break;
        end

end

%PROCESS DATA TO FIND TRENDS
heighttrend(heighttrend==0) = []; %remove all zero entries (images that did not have bubbles) from bubbletrend
heighttrend = heighttrend'; %transpose bubbletrend to make it column vector
x=(1:size(heighttrend))'; %create array of integer values from 1 to new size of bubbletrend
true_basetrend(true_basetrend==0) = []; %remove zero entries from heightbasetrend
true_basetrend = true_basetrend'; %transpose array
%If user only selected one image and it had a bubble, the bubble height is displayed:
if (size(x,1)==1)  
    fprintf('Height of droplet: %d pixels', height);
    fprintf(newline);
%If user only selected one image and it did not have a bubble, error message is displayed:    
elseif (size(x,1)==0) 
    fprintf('The image you selected does not appear to have a reaction droplet.'); 
    fprintf(newline);
    fprintf('This can occur if images were taken prior to pipetting droplet into chip,');
    fprintf(newline);
    fprintf('or if the droplet flattened at the end of the reaction.');
    fprintf(newline);
%If user selected multiple images containing bubbles, a plot is generated:
else 
    f = fit(x, heighttrend, 'exp1'); %create exponential best fit line for bubbletrend
    figure(100); plot(f, x, heighttrend); title ('Height of Reaction Droplet (Pixels) for E. coli target'); xlabel('Time'); ylabel('Height (pixels)'); ylim([0 inf]);
    disp(f);
    figure(101); plot(x, true_basetrend); title('True base length recorded at each time point'); xlabel('Time'); ylabel('Base length (pixels)'); ylim([0 inf]);
end
%save(fullFileName, 'heighttrend', 'basetrend');