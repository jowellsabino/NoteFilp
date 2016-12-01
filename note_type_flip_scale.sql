create temp table test as
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
	 )