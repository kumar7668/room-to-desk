 SELECT 
                  r.id
                , (SELECT z.title FROM sys_code z WHERE z.code=r.status_cd)  status
                , CASE
                        WHEN r.status_cd='status.draft' AND t.nomination_yn='Y' AND DATE(t.event_dt) > DATE(NOW())  THEN 'status.nomination.request'
                        ELSE r.status_cd
                    END status_cd 
				, t.mandatory_yn
                , t.nomination_yn
                , r.role_cd
                , t.id training_id  
                , t.title
                , t.ref_link
                , t.trainer_id                
                , t.feedback_show_yn
                , t.skill_id
                , (SELECT z.title FROM skill z WHERE z.id=t.skill_id AND z.del_yn='N')  skill
                , t.current_level_cd
                , (SELECT z.title FROM sys_code z WHERE z.code=t.current_level_cd AND z.del_yn='N')  current_level_nm
                , t.target_level_cd
                , (SELECT z.title FROM sys_code z WHERE z.code=t.target_level_cd AND z.del_yn='N')  target_level_nm
                , t.project_id
                , DATE(t.event_dt) event_dt
                , t.start_time 
                , t.end_time  
                , t.event_type_cd
                , (SELECT z.title FROM sys_code z WHERE z.code=t.event_type_cd AND z.del_yn='N')  event_type
                , t.location  
                                
                , CASE
                        WHEN t.status_cd='status.draft' AND DATE(t.event_dt)= DATE(NOW())  THEN 'status.inprogress'
                        WHEN t.status_cd='status.draft' AND DATE(t.event_dt) > DATE(NOW()) THEN 'status.upcoming'
                        WHEN t.status_cd='status.draft' AND  DATE(NOW()) > DATE(t.event_dt) THEN 'status.action.awaiting'
                        ELSE t.status_cd
                    END training_status_cd         
                
                , (SELECT IF(t.status_cd='status.draft' AND DATE(t.event_dt)= DATE(NOW()),'InProgress'
                            , IF(t.status_cd='status.draft' AND DATE(t.event_dt) > DATE(NOW()),'Upcoming'
                                , IF(t.status_cd='status.draft' AND  DATE(NOW()) > DATE(t.event_dt) ,'Action Awaiting'
                                , z.title ) )
                            )  FROM sys_code z WHERE z.code=t.status_cd AND z.del_yn='N')  training_status

                 , (SELECT IF(t.status_cd='status.draft' AND DATE(t.event_dt)= DATE(NOW()),5
                            , IF(t.status_cd='status.draft' AND DATE(t.event_dt)> DATE(NOW()),4
                                , 0 )
                            )  FROM sys_code z WHERE z.code=t.status_cd AND z.del_yn='N')  sno
                , (SELECT COUNT(*) FROM content_training_member z WHERE z.training_id=t.id AND z.del_yn='N')  member_count
            FROM 
                content_training t
                ,content_training_member r
            WHERE 1=1
                AND t.id = r.training_id    
              
                    AND r.member_id= 61      
					 AND r.role_cd='training.role.attendee'
                AND (
				CASE
					WHEN t.status_cd='status.draft' AND DATE(NOW()) > DATE(t.event_dt) THEN 'status.action.awaiting'
                    When r.status_cd NOT IN ('status.feedback.complete','status.reject','status.nomination.reject') AND t.status_cd NOT IN('status.draft') AND DATE(t.event_dt) < DATE(NOW()) THEN 'status.feedback.request'
					WHEN r.status_cd IN ('status.draft', 'status.approval.request') AND t.mandatory_yn = 'Y' AND t.nomination_yn = 'N' AND DATE(t.event_dt) > DATE(NOW()) THEN 'mandatory_yn.request'
					WHEN r.status_cd NOT IN ('status.feedback.complete','status.reject','status.nomination.reject','status.reject') AND NOT (t.status_cd ='status.comaplte' AND DATE(t.event_dt) < DATE(NOW())) THEN 'status.upcoming.request'

					
                    ELSE t.status_cd
				END
			        ) = "status.upcoming.request"
           
                AND t.del_yn='N'
                AND t.show_yn='Y'
                AND r.del_yn='N'
                ORDER BY sno DESC





%%%%

CASE
    -- 1. Feedback Request (Past Trainings)
    WHEN r.status_cd NOT IN ('status.feedback.complete', 'status.reject', 'status.nomination.reject')
         AND t.status_cd NOT IN ('status.draft')
         AND DATE(t.event_dt) < DATE(NOW())
    THEN 'status.feedback.request'

    -- 2. Upcoming Mandatory Trainings (No nomination, but forced)
    WHEN r.status_cd IN ('status.draft', 'status.approval.request')
         AND t.mandatory_yn = 'Y'
         AND t.nomination_yn = 'N'
         AND DATE(t.event_dt) > DATE(NOW())
    THEN 'mandatory_yn.request'

    -- 3. Upcoming Self-assigned Trainings (Not nominated, not mandatory)
    WHEN r.status_cd = 'status.draft'
         AND t.mandatory_yn = 'N'
         AND t.nomination_yn = 'N'
         AND t.status_cd = 'status.draft'
         AND DATE(t.event_dt) > DATE(NOW())
    THEN 'self_assigned.request'

    -- 4. Upcoming Nominated Trainings (Nomination needed)
    WHEN t.nomination_yn = 'Y'
         AND r.status_cd IN ('status.draft', 'status.approval.request')
         AND t.status_cd = 'status.draft'
         AND DATE(t.event_dt) > DATE(NOW())
    THEN 'status.upcoming.request'

    ELSE r.status_cd
END AS status_cd



##############

