#------------------------------------------------------------------------------
# gcomp.awk                                                      SPU 24.10.2024
#
# Author: Stefano Purchiaroni (info@purchiaroni.com)
#
# GCode composer
#
# This script composes more GCode parts exported from LaserGRBL into a single
# block, creating an array of copies of Vectorised or Line-per-line'd elements.
# The indicated shift is applied. The power range may be re-mapped in the
# indicated limit.
# 
# How to 
#
# Prepare a test.cfg file and launch the script under CygWin:
# $ awk [-v diag=n] -f gcomp.awk test.cfg
#
# The diagnostic level may be: 0:None, 1:Major, 2:Detailed
# The errors are always shown.
#
# Some commented examples of configuration (cfg) files are supplied.
#------------------------------------------------------------------------------

function PutFile() {
# Manage the current file and queue it in the Output File

  if (diag >= 1) printf "Put " InputFile " at (" Xof "," Yof ") ";
  print "; ---- gcomp: insert " InputFile " at (" Xof "," Yof "), scale Smax from " Smax " to " Smax2 >> OutFile;
  nlines=0;
  close(InputFile);
  while ((getline lin < InputFile) > 0) {
    nlines++;
    n=split(lin,s); 
    for (i=1;i<=n;i++) {
      if ((substr(s[i],1,1)=="X") && (Xof>0)) {
        v=substr(s[i],2);
        v+=Xof;
        s[i]="X" v;
      }
      else if ((substr(s[i],1,1)=="Y") && (Yof>0)) {
        v=substr(s[i],2);
        v+=Yof;
        s[i]="Y" v;
      }
      else if ((substr(s[i],1,1)=="S") && (Smax>0) && (Smax2>0)) {
        if (diag>=2) printf "Smax mapping: " s[i];
        v=substr(s[i],2);
        v=int((v*Smax2)/Smax);
        s[i]="S" v;
        if (diag>=2) print "-->" s[i];
      }
      if (diag>=2) printf s[i];
      printf s[i] >> OutFile;
      if (i<n) {
        if (diag>=2) printf " "; 
        printf " " >> OutFile; 
      }
      else {
        if (diag>=2) print "";       
        print "" >> OutFile;
      }  
    }
  }
  print "; ---- gcomp: " nlines " inserted." >> OutFile;
  close(InputFile);
  if (diag >= 1) print nlines " lines.";
} 

#------------- MAIN -----------------------------------------------------------


             { if (diag >= 1) { print "> " $0; } }     # Diagnostic: echo lines

# Get the user defined parameters and commands from the configuration file

/Smax/       {                                         # Collect Smax 
               if (NF == 3) {
                 Smax=$2; Smax2=$3;                      
                 if (diag>=1) 
                   print "Smax mapped from " Smax " to " Smax2; 
               } 
               else {
                 print "(!) Smax expects two numeric arguments";
                 exit;
               }
             }  
                                  
/OutFile/    {                                         # Collect OutFile 
               if (NF == 2) {
                 OutFile=$2;                             
                 if (diag >= 1) print "Output to " OutFile;
                 cmd = "rm -f " OutFile;
                 system(cmd);                          # Raz the output file
               } 
               else {
                 print "(!) OutFile expects a filename as argument"  
                 exit;
               }
             }

/InputFile/  { InputFile=$2; }                         # Collect input filename

/PutAt/      { Xof=$2; Yof=$3; Pass=$4;                # Collect offset and no. of passes
               for (ipass=1; ipass<=Pass; ipass++) 
                 PutFile();                            # Treat and queue the input file 
             }    


