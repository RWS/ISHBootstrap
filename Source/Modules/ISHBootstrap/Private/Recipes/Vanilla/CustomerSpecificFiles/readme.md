
CONTENT
=======

The "FilesToCopy" directory is for prepared files for a specific InfoShare version.
During recipe execution files from this directory will be applied on target system using Copy-ISHFile cmdlet.

FLOW
====

1. Prepare files with InfoShare customizations
1. Create "FilesToCopy" directory inside "CustomerSpecificFiles"
1. Place customized files in "FilesToCopy" directory preserving file structure
   Note: The "FilesToCopy" folder can contain only folders "Applications", "Database", "DocTypes", "Websites".
   During file copying the placeholder like "#!#installtool:SomeValueName#!#" in files will be replaced with
   corresponding parameters of specified deployment.
