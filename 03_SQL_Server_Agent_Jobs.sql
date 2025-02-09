-------------------------------------
-- 3: SQL Server Agent
-------------------------------------

USE msdb;
GO

-- Create new job 
DECLARE @jobId BINARY(16)
EXEC sp_add_job @job_name=N'TestJob', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Description for TestJob', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'LoginName', @job_id = @jobId OUTPUT;
GO

-- Adding the create job to server
EXEC msdb.dbo.sp_add_jobserver @job_name=N'TestJob', @server_name = N'MachineName'
GO

-- Add step to the created job
EXEC sp_add_jobstep @job_name=N'TestJob', @step_name=N'Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Backup database testdb to disk=''c:\db\backup\testdb.bak'';', 
		@database_name=N'TestDB', 
		@flags=0

-- Creating schedule for create job
EXEC  msdb.dbo.sp_add_jobschedule @job_name=N'TestJob', @name=N'daily-midenight', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190707, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959;
GO

-- Creating an operator
EXEC sp_add_operator @name=N'amin', 
		@enabled=1, 
		@weekday_pager_start_time=80000, -- this means 8:00AM
		@weekday_pager_end_time=180000, -- this means 18:00
		@saturday_pager_start_time=80000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=126, 
		@email_address=N'amin@mesbahi.net', 
		@category_name=N'[Uncategorized]'
GO

-- Get list of all jobs
SELECT job_id, [name] FROM sysjobs;


-- List of all the jobs currently running on server
SELECT [name], [enabled], [description], step_name, command, [server], [database_name]
FROM sysjobs job
INNER JOIN sysjobsteps steps        
ON job.job_id = steps.job_id