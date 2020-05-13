/***

This macro is to automatially segment chloroplasts in images of leaf tissue. 
It measures the mean, min and max flourescence intensity for each chloroplast 
in the mNeon/GFP/other fluorescent protein channel and the chlorophyll autofluorescence channel.
The idea is that these measurements can be used to calculate the number of chloroplasts that are expressing a protein 
with flourescent tag.

 This Macro is based on the the method for automatically segmenting nucei described here https://imagej.net/Nuclei_Watershed_Separation
 
 
 Limitations:  mesophyll chloroplasts are often bunched together and some do not have a round shape and are therefore sometimes 
 'lumped together' during the segmentation. 
 To comabt this you an exclde ROIs with a large area from the analysis. I am working on a future verison to include this automatically.

 
 */






//function iterateseries(series)
#@ File (label = "Input file", style = "file") input 				//choose the .lif file
#@ File (label = "Output directory", style = "directory") output 	//choose where to save your JPEG images
#@ String (label = "Series start number", style = "string") m 		//choose the start of the series range
#@ String (label = "Series end number", style = "string") n 		//choose the end of your series range


//This will iterate through a defined range of series in the .lif file (you will need to
//know the number of series in advance 
iterate();

function iterate(){
for (i=m; i<n ;i++) {
	processFile(input, i);
        }
}

//this is the function to open and process the images in the .lif file
function processFile(input, i) {
		f = "series_"+i;
	   	run("Bio-Formats Importer", "open=["+input+"] color_mode=Colorized rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT "+f+"");

//get the title of the stacked images
		title = getTitle();
		
//now split the channels, this will split stacked channels into individual image windows that will 
//start with "Cx-" where x is the channel number. So Channel 1 will be: "C1-......"
		run("Split Channels");

//create variables for each channel so we can generically use them 
		ch1 = "C1-"+title; 
		ch2 = "C2-"+title;
		ch3 = "C3-"+title;


selectWindow(ch2);
run("Duplicate...", 1); 			//this duplicates the chloroplast autofluorescence channel so we can use it to create a mask
selectWindow(ch2+"-1");				// select the duplicated channel (ImageJ has added "-1" to the end of the new image name)
run("Gaussian Blur...", "sigma=3"); //this applies a blur
run("Threshold...");				// apply a threshold
setThreshold(41, 255);				//this can be changed 0-255 is max range for 8-bit image
setOption("BlackBackground", true);	// make sure this is true
run("Convert to Mask");
run("Watershed");					
run("Analyze Particles...", "  show=Outlines display clear add");
close("Results");														// closing the results window here stops the ROI measurements from the mask getting included with the results for each channel
selectWindow(ch1);														//select channel 1
roiManager("Measure");													//measure Area, mean, min and max fluorescence intensity for each ROI/segmented chloroplast
saveAs("Results", "/Users/liatadler/Lab/"+title+"mNeon-measured.csv"); 	// save results as .csv file
close("Results");
selectWindow(ch2);
roiManager("Measure");
saveAs("Results", "/Users/liatadler/Lab/"+title+"Chl-measured.csv");

}