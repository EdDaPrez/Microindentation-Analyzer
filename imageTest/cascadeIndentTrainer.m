negativeFolder = 'C:\Users\Eduar\OneDrive\Documents\TU\AMDG\negativeIndent';%change this to whatever folder holds your negative images
NumStages = 20;
FAR = .025;

trainCascadeObjectDetector('indentDetector_20_025.xml', realIndents, negativeFolder, 'NumCascadeStages', NumStages, 'FalseAlarmRate',FAR);%realIndents imported from matlab image segmentation app