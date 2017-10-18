//*//*//*//
//Macro to split and transform images from the dual camera setting
//*//*//*//
Dialog.create("Macro Output");
Dialog.addMessage("Warning:\n To ensure that the macro works properly, file names with spaces \n or brackets are replaced by underscores.");
items = newArray("yes","no");
Dialog.addRadioButtonGroup("Do you want to use the silent mode (processed images are not shown)?",items,2,1,"no");
Dialog.show();
mode = Dialog.getRadioButton();

if (mode == "yes"){
	setBatchMode(true);
}

///// Functions
//List only tif files in folder
function listFiles(dir) {
	filelist = newArray(0);
	list = getFileList(dir);
    for (i=0; i<list.length; i++) {
    	if (endsWith(list[i], "tif") || endsWith(list[i], "TIF")) {
    		filelist = append(filelist,list[i]);
    	}
     }
	return filelist;
  }

// Append items to array
function append(arr, value) {
	arr2 = newArray(arr.length+1);
    for (i=0; i<arr.length; i++)
    	arr2[i] = arr[i];
    arr2[arr.length] = value;
    return arr2;
  }

//Split images in half 
function splitHalfes(image) {
	label = getTitle();								//get name of image
	height = getHeight();							//height of image
	width = getWidth();								//width of image
	halfWidth = width/2;						
	makeRectangle(0,0,halfWidth,height);			//select left side of image
	run("Duplicate...","title=Left_"+label);
	selectWindow(label);
	makeRectangle(halfWidth,0,halfWidth,height);	//select right side of image
	run("Duplicate...","title=Right_"+label);
	return label;
}

/////Split and transform images
//Select if images have to be calibrated first
Dialog.create("Calibration");
items = newArray("yes","no");
Dialog.addRadioButtonGroup("Calibrate images?",items,2,1,"yes");
Dialog.show();

//Save selection in variable
choice = Dialog.getRadioButton();

//If calibration is needed, select calibration image and generate transformation matrix
if (choice=='yes') {
	waitForUser("Select calibration image");
	calibration = File.openDialog("Select a File");		//select calibration image
	
//Use calibration image to generate transformation matrix
	if (endsWith(calibration,"tif")) {					//check if image is tif file
		open(calibration);								//open file
		dir = getDirectory("image");
		matrix = dir+"Transformation_Matrix.txt";		//create file name for transformation matrix
		open(calibration);
		label = splitHalfes(calibration);

		//use MultiStackReg to align calibration images and generate the transformation matrix
		run("MultiStackReg", "stack_1=Left_"+label+" action_1=[Align] file_1=["+matrix+"] stack_2=Right_"+label+" action_2=[Align to First Stack] file_2=["+matrix+"] transformation=[Rigid Body] save");								 	
		run("Close All");	
	} else {
		Dialog.create("Error");
		Dialog.addMessage("The selected file is not a tif image.");
		Dialog.show();
	}
}
//if no calibration is needed, select the transformation matrix
else {
	waitForUser("Select transformation matrix");
	matrix = File.openDialog("Select a File");		//select transformation matrix
}

//Select source directory for images to be processed
waitForUser("Select Image Directory");
dir = getDirectory("Select Image Directory");
run("Fix Funny Filenames", "which="+dir);

//If there is only one image in the folder, process it
list=listFiles(dir); 

if (list.length==1) {
	filename = list[0];			
	open(filename);	
	label = getTitle();
	label = replace(label, ".TIF","");
	run("Stack to Images");
	I = nImages();
	titles = getList("image.titles");
	
	for (i=0; i<I; i++) {		
		selectWindow(titles[i]);
		label_s = splitHalfes(titles[i]);
	
		//use MultiStackReg to align and transform images with transformation matrix
		run("MultiStackReg", "stack_1=Left_"+label_s+" action_1=[Use as Reference] file_1=["+matrix+"] stack_2=Right_"+label_s+" action_2=[Load Transformation File] file_2=["+matrix+"] transformation=[Rigid Body]");
	}
	run("Images to Stack"," name=Left_ title=Left_ use");
	saveAs("Tiff",dir+label+"_left.tif");
	run("Images to Stack"," name=Right_ title=Right_ use");
	saveAs("Tiff",dir+label+"_right.tif");
	run("Close All");
	
}else {
	// If there are several tif files in folder
	//Select which images to process
	Dialog.create("Images");
	items2 = newArray("only selected images","all images");
	Dialog.addRadioButtonGroup("Which images do you want to process?",items2,2,1,"all images");
	Dialog.show();

	//Save selection in variable
	choice2 = Dialog.getRadioButton();
	//image_list = getFileList(dir);

	//If all images are chosen
	if (choice2=="all images") {
		//Loop through all files in image directory
		for (i=0; i<list.length; i++){
		
			filename = dir+list[i];			
			open(filename);	
			label = getTitle();
			label = replace(label, ".TIF","");
			print("Process image "+(i+1)+" of "+list.length);	
			run("Stack to Images");
			I = nImages();
			titles = getList("image.titles");
	
			for (j=0; j<I; j++) {		
				selectWindow(titles[j]);
				label_s = splitHalfes(filename);

				//use MultiStackReg to align and transform images with transformation matrix
				run("MultiStackReg", "stack_1=Left_"+label_s+" action_1=[Use as Reference] file_1=["+matrix+"] stack_2=Right_"+label_s+" action_2=[Load Transformation File] file_2=["+matrix+"] transformation=[Rigid Body]");
				}
			run("Images to Stack"," name=Left_ title=Left_ use");
			saveAs("Tiff",dir+label+"_left.tif");
			run("Images to Stack"," name=Right_ title=Right_ use");
			saveAs("Tiff",dir+label+"_right.tif");
			run("Close All");
		}
	} else {
		//if only a specific file should be processed
		waitForUser("Select image for processing");
		filename = File.openDialog("Select a File");
		if (endsWith(filename,"tif") || endsWith(filename, "TIF")) {			
			open(filename);
			label = getTitle();
			label = replace(label, ".TIF","");
			run("Stack to Images");
			I = nImages();
			titles = getList("image.titles");
	
			for (i=0; i<I; i++) {		
				selectWindow(titles[i]);
				label_s = splitHalfes(filename);

				//use MultiStackReg to align and transform images with transformation matrix
				run("MultiStackReg", "stack_1=Left_"+label_s+" action_1=[Use as Reference] file_1=["+matrix+"] stack_2=Right_"+label_s+" action_2=[Load Transformation File] file_2=["+matrix+"] transformation=[Rigid Body]");
			}
			run("Images to Stack"," name=Left_ title=Left_ use");
			saveAs("Tiff",dir+label+"_left.tif");
			run("Images to Stack"," name=Right_ title=Right_ use");
			saveAs("Tiff",dir+label+"_right.tif");
			run("Close All");
	} else {
		Dialog.create("Error");
		Dialog.addMessage("The selected file is not a tif image.");
		Dialog.show();
		}
}
selectWindow("Log");
run("Close");

Dialog.create("DualCam");
Dialog.addMessage("Done!");
Dialog.show();
