//*//*//*//
//Macro to split and transform images from the dual camera setting
//*//*//*//
////////////////////////////////
////////// Functions //////////
///////////////////////////////
//List only tif files in folder
osSystem = getInfo("os.name");

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

// add leading zeros to image number
function pad(number,zeros) {
	string = toString(number);
	while (lengthOf(string) < zeros) {
		string = "0" + string;
	}
	return string;
}

// split image and save to temporary directory
function processImage(image,dir) {
	open(dir+image);	
	label = getTitle();
	label = replace(label, ".TIF","");
	label = replace(label, ".tif","");
	I = nSlices();

	for (i=0; i<I; i++) {
		selectWindow(label+".tif");
		if (i<I-1) {
			run("Make Substack...", "delete slices=1");	
			title = getTitle();
		} else {
			title = label+".tif"; 
		}
		label_s = splitHalfes(title);
		stringI = toString(I);
		zeros = lengthOf(stringI)+1;
		number_s = pad(i,zeros);
		run("MultiStackReg", "stack_1=Left_"+label_s+" action_1=[Use as Reference] file_1=["+matrix+"] stack_2=Right_"+label_s+" action_2=[Load Transformation File] file_2=["+matrix+"] transformation=[Rigid Body]");
		run("Images to Stack"," name=Left_ title=Left_ use");
		saveAs("Tiff","/tmp/Left/"+label+"_"+number_s+"_left.tif");
		run("Images to Stack"," name=Right_ title=Right_ use");
		saveAs("Tiff","/tmp/Right/"+label+"_"+number_s+"_right.tif");
		selectWindow(label+"_"+number_s+"_left.tif");
		run("Close");
		selectWindow(label+"_"+number_s+"_right.tif");
		run("Close");
		selectWindow(title);
		run("Close");
	}
	return label;
}

function deleteTmpFiles(dir,label) {
	if (startsWith(osSystem, "Windows")) {
		list_left = listFiles("\\tmp\\Left\\");
		list_right = listFiles("\\tmp\\Right\\");
	} else {
		list_left = listFiles("/tmp/Left/");
		list_right = listFiles("/tmp/Right/");
	}

	for (j=0; j<list_left.length; j++) {
		filename = list_left[j];
		if (startsWith(osSystem, "Windows")) {
			open("\\tmp\\Left\\"+filename);
			ok = File.delete("\\tmp\\Left\\"+filename);
		} else {
			open("/tmp/Left/"+filename);
			ok = File.delete("/tmp/Left/"+filename);
		}
	}
	run("Images to Stack"," name=_left title=_left use");
	saveAs("Tiff",dir+label+"_left.tif");
	run("Close");

	for (j=0; j<list_right.length; j++) {
		filename = list_right[j];
		if (startsWith(osSystem, "Windows")) {
			open("\\tmp\\Right\\"+filename);
			ok = File.delete("\\tmp\\Right\\"+filename);
		} else {
			open("/tmp/Right/"+filename);
			ok = File.delete("/tmp/Right/"+filename);
		}
	}
	run("Images to Stack"," name=_right title=_right use");
	saveAs("Tiff",dir+label+"_right.tif");
	run("Close");
}
//////////////////////////////
////////// Welcome //////////
/////////////////////////////
Dialog.create("Macro Output");
Dialog.addMessage("Warning:\n To ensure that the macro works properly, file names with spaces \n or brackets are replaced by underscores.");
items = newArray("yes","no");
Dialog.addRadioButtonGroup("Do you want to use the silent mode (processed images are not shown)?",items,2,1,"no");
Dialog.show();
mode = Dialog.getRadioButton();

if (mode == "yes"){
	setBatchMode(true);
}

//setOption("JFileChooser", true);
//temporary folders for processed images
if (startsWith(osSystem, "Windows")) {
	File.makeDirectory("\\tmp\\Left\\");
	File.makeDirectory("\\tmp\\Right\\");
} else {
	File.makeDirectory("/tmp/Left/");
	File.makeDirectory("/tmp/Right/");		
}

/////////////////////////////////
////////// Calibration //////////
////////////////////////////////
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
	if (endsWith(calibration,"tif") || endsWith(calibration,"TIF")) {					//check if image is tif file
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

////////////////////////////
////////// Images //////////
///////////////////////////
//Select source directory for images to be processed
waitForUser("Select Image Directory");
dir = getDirectory("Select Image Directory");
run("Fix Funny Filenames", "which="+dir);

//If there is only one image in the folder, process it
list=listFiles(dir); 

if (list.length==1) {
	filename = list[0];			
	label = processImage(filename,dir);
	deleteTmpFiles(dir,label);
}else {
	// If there are several tif files in folder
	//Select which images to process
	Dialog.create("Images");
	items2 = newArray("only selected image","all images");
	Dialog.addRadioButtonGroup("Which images do you want to process?",items2,2,1,"all images");
	Dialog.show();

	//Save selection in variable
	choice2 = Dialog.getRadioButton();
	//image_list = getFileList(dir);

	//If all images are chosen
	if (choice2=="all images") {
		//Loop through all files in image directory
		for (i=0; i<list.length; i++){
		
			filename = list[i];			
			label = processImage(filename,dir);
			deleteTmpFiles(dir,label);
		}	
	} else {
		//if only a specific file should be processed
		waitForUser("Select image for processing");
		filename = File.openDialog("Select File");

		if (endsWith(filename,"tif") || endsWith(filename, "TIF")) {			
				label = processImage(filename,dir);
				deleteTmpFiles(dir,label);
		} else {
			Dialog.create("Error");
			Dialog.addMessage("The selected file is not a tif image.");
			Dialog.show();
		}
		}
		
}
if (isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}
if (startsWith(osSystem, "Windows")) {
	ok = File.delete("\\tmp\\Left\\");
	ok = File.delete("\\tmp\\Right\\");
} else {
	ok = File.delete("/tmp/Left/");
	ok = File.delete("/tmp/Right/");
}

Dialog.create("DualCam");
Dialog.addMessage("Done!");
Dialog.show();