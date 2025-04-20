/* Initial Data Processing with Error Handling */
data adam_ae;
    set ae02;

    /* Check for missing date values */
    if missing(AESTDT) or missing(AEENDT) or missing(RFSTDTC) then do;
        put "ERROR: Missing date values for AE data.";
        return;
    end;

    /* Date conversion */
    AESTDY = (AESTDT - RFSTDTC) + 1;
    AEENDY = (AEENDT - RFSTDTC) + 1;

    /* Recode variables */
    AESER = ifc(upcase(AESER) = 'Y', 'Y', 'N');
    select (upcase(AESEV));
        when ('MILD') AESEV = 1;
        when ('MODERATE') AESEV = 2;
        when ('SEVERE') AESEV = 3;
        otherwise AESEV = .; /* Handle unknown values */
    end;
    AEOUT = ifc(upcase(AEOUT) = 'DEATH', 'Y', 'N');
    AELAST = ifn(last.USUBJID, 'Y', 'N');
run;

/* Sequence Generation */
retain AESEQ 0;
if first.USUBJID then AESEQ = 1;
else AESEQ + 1;

/* Merge with SE dataset */
proc sort data=adam_ae; by usubjid; run;
proc sort data=se; by usubjid; run;

data adam_ae;
    merge adam_ae (in=a) se (in=b keep=usubjid epoch);
    by usubjid;
    
    if a; /* Only keep records from adam_ae */

    /* If no matching record from 'se', handle missing EPOCH */
    if not b then AESEQ = .;
run;

/* Export ADaM Dataset */
%let output_dir = C:\path\to\output;
%if %sysfunc(fileexist(&output_dir)) = 0 %then %do;
    %put ERROR: Directory &output_dir does not exist!;
    return;
%end;

libname adam xport "&output_dir\adam_ae.xpt";
proc copy in=work out=adam;
    select adam_ae;
run;
