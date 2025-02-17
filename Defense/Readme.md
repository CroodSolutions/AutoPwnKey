
From a defensive perspective, our recommendations are pretty straightforward:
 - Block AHK via GPO/AppLocker or other application control solution. 
 - A custom-IOA in your EDR solution to block AutoHotKey will also work, if this option is available to you.  
 - Longer term, consider strict application control / allow-listing.

We will update this section with more detailed instructions later, but the process is pretty straightforward.  

Note - you may need to check your environment for valid use of AutoHotKey, although typically if it is being used in a modern enterprise environment, it is likely to be shadow IT anyway.  
