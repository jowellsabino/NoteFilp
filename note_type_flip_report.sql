select    ce.parent_event_id
		, p.name_full_formatted as PatientName
		, ea.alias as CSN
		, cvec.display as "NoteType (original, flipped to)"
		, pr.name_full_formatted as LastUpdateBy
		, ce.updt_dt_tm as LastUpdateDateTime
    --- , ce.event_cd as NoteTypeEventCode
from CHBPROD.ADMIN.V500_PERSON p,
	 CHBPROD.ADMIN.V500_CLINICAL_EVENT ce,
	 CHBPROD.ADMIN.V500_ENCNTR_ALIAS ea,
	 CHBPROD.ADMIN.V500_CODE_VALUE cvec,
	 CHBPROD.ADMIN.V500_PRSNL pr,
	 (
		-- relink to clinical_event to get event code and clinical_event_id for instances of note type flipping
		  select ceec.parent_event_id,ceec.event_cd,max(ceec.clinical_event_id) as maxce
		    from CHBPROD.ADMIN.V500_CLINICAL_EVENT ceec,
		  		 (  --- aggce
				    --- Get documentation events that has more than one event_cd (note type) associated with it
				    select aggnt.parent_event_id
				      from 
				  		   (  --- aggnt
							  --- Aggregate clinical events related to documentation by 
							  ---   instance (parent_event_id) and event_cd (note type) unique pairs
							  select cvesc.display as DocFolder,cea.parent_event_id,cea.event_cd
 		           			    from  CHBPROD.ADMIN.V500_CLINICAL_EVENT cea,
							    	  CHBPROD.ADMIN.V500_V500_EVENT_SET_EXPLODE esea,
									  CHBPROD.ADMIN.V500_CODE_VALUE cvesc
 		           			    where cea.updt_dt_tm between to_date('01-Nov-2016 00:00:00','DD-Mon-YYYY HH24:MI:SS') and now() 
								  and cea.event_class_cd = 224       --- mdoc event class only
								  and cea.event_cd = esea.event_cd
								  and esea.event_set_cd in (33126742,67678568) --- Include event codes under the Clinic notes event set (32126742) only
								  and esea.event_set_cd = cvesc.code_value
						     group by cvesc.display,cea.parent_event_id,cea.event_cd
						   ) aggnt
				  group by aggnt.parent_event_id
				    having count(*) > 1
				 ) aggce 
		   where ceec.parent_event_id = aggce.parent_event_id
		     and ceec.event_class_cd = 224 --- need to qualify on mdoc only, since parent will also include doc class type for all children
	    group by ceec.parent_event_id,ceec.event_cd
	 ) aggdoc
where aggdoc.parent_event_id = ce.parent_event_id
  and ce.event_class_cd = 224
  and p.person_id = ce.person_id
  and ea.encntr_id = ce.encntr_id
  and ea.encntr_alias_type_cd = 1077 -- CSN only
  and cvec.code_value = ce.event_cd
  and ce.clinical_event_id = aggdoc.maxce
  and ce.updt_id = pr.person_id
group by ce.parent_event_id,p.name_full_formatted,ea.alias,ce.event_cd,cvec.display,pr.name_full_formatted,ce.updt_dt_tm 
 order by p.name_full_formatted,ea.alias,ce.updt_dt_tm 
 ---limit 100;