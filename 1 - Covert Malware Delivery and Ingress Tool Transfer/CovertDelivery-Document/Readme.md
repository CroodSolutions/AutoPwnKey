---Summary---

The script here is to setup a weaponized document attack simulation, using AHK, a certificate file hiding executables, orchestrated by a VBA script to hide a self-contained attack within a single Excel document. Setup steps include creating a lure spreadsheet with two ActiveX objects, each in different tabs (that you will later hide).  In one object/tab you will paste the text of a certutil encoded version of AutoHotKey64.exe and in the other you will paste the text for the latest version of the AutoPwnKey agent, adjusting the IP for the location of your server. With proper setup, this will allow for a document that runs a macro on open that will write the AutoHotKey64.exe file to the current working as a pem file, then rename it as AutoHotKey64.exe, followed by wrtiting the AHK listener script to the current working directory, and then run it using the AHK exe. It will then beacon to the remote listener location you have specified, compatible with the AutoPwnKey listener.  

---Recent Testing Notes---

This proved evasive against at at least one EDR, but was detected by email and cloud AV solutions. An updated version will be released in a few days, fixing a few issues that will make it a more useful testing tool for weaponized document delivery.  

---Setup Steps---

 - Create the lure document.
 - Create two blank tabs and name them.
 - Enable developer tab on the ribbon.
 - Add ActiveX text box on each tab.
 - Download the AutoHotkey64.exe file.
 - Use certutil - encode to create a cert file text version of this exe.
 - Paste this into one of the ActiveX objects in the speadsheet.
 - Retrieve the most recent version of the AutoPwnKey agent from this repo.
 - Paste it into the other ActiveX object.
 - Align naming between the VBA script provided and your lure doc; they are probably not the same out of the box.
 - QA it on a VM running MS Excel.
 - Create your campaign including your email send server, domain, and message/lure.
 - Send / monitor.
 - Monitor the C2 module / server for connections.

---Ethical Considerations---

These tools are made to help raise awarness about some serious security gaps adversaries are exploiting in the wild, by providing penetration testing / red team resources. Use of these tools assume an ethical blue/purple/red team scenario where you are using these tools to ethically test your security posture and controls. We do not support or endorse malicious or criminal use of assessment, security, or administrative tools.  
