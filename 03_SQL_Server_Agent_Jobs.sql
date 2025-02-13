/**************************************************************
 * SQL Server Agent Tutorial
 * Description: This script demonstrates how to create and manage
 *              SQL Server Agent jobs, including job creation,
 *              adding steps, scheduling, and creating operators.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are in the msdb database where SQL Server Agent jobs reside.
*/
USE msdb;
GO

-------------------------------------------------
-- Region: 1. Creating a New SQL Server Agent Job
-------------------------------------------------
/*
  1.1 Create a new job and capture the job ID.
*/
DECLARE @jobId BINARY(16);
EXEC sp_add_job 
    @job_name = N'TestJob', 
    @enabled = 1, 
    @notify_level_eventlog = 0, 
    @notify_level_email = 0, 
    @notify_level_netsend = 0, 
    @notify_level_page = 0, 
    @delete_level = 0, 
    @description = N'Description for TestJob', 
    @category_name = N'[Uncategorized (Local)]', 
    @owner_login_name = N'LoginName', 
    @job_id = @jobId OUTPUT;
GO

/*
  1.2 Add the job to the server. 
  Replace 'MachineName' with the target server name.
*/
EXEC msdb.dbo.sp_add_jobserver 
    @job_name = N'TestJob', 
    @server_name = N'MachineName';
GO

-------------------------------------------------
-- Region: 2. Adding Job Steps
-------------------------------------------------
/*
  2.1 Add a step to the created job.
  This example demonstrates a T-SQL step that backs up the database.
*/
EXEC sp_add_jobstep 
    @job_name = N'TestJob', 
    @step_name = N'Step1', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 3,  -- 3 means go to the next step
    @on_success_step_id = 0, 
    @on_fail_action = 2,     -- 2 means quit the job reporting failure
    @on_fail_step_id = 0, 
    @retry_attempts = 2, 
    @retry_interval = 1,     -- Retry interval in minutes
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'BACKUP DATABASE TestDB TO DISK = N''C:\db\backup\testdb.bak'';', 
    @database_name = N'TestDB', 
    @flags = 0;
GO

-------------------------------------------------
-- Region: 3. Creating Job Schedules
-------------------------------------------------
/*
  3.1 Create a schedule for the job.
  In this example, the job is scheduled to run daily at midnight.
*/
EXEC msdb.dbo.sp_add_jobschedule 
    @job_name = N'TestJob', 
    @name = N'daily-midnight', 
    @enabled = 1, 
    @freq_type = 4,                -- Daily frequency
    @freq_interval = 1, 
    @freq_subday_type = 1,         -- Occurs once per day
    @freq_subday_interval = 0, 
    @freq_relative_interval = 0, 
    @freq_recurrence_factor = 0, 
    @active_start_date = 20190707, -- Format: YYYYMMDD
    @active_end_date = 99991231,   -- Use a high number for no end date
    @active_start_time = 0,        -- Start time in HHMMSS (midnight)
    @active_end_time = 235959;     -- End time in HHMMSS (end of day)
GO

-------------------------------------------------
-- Region: 4. Creating an Operator
-------------------------------------------------
/*
  4.1 Create an operator to receive notifications.
  Modify the pager times and email address as needed.
*/
EXEC sp_add_operator 
    @name = N'amin', 
    @enabled = 1, 
    @weekday_pager_start_time = 80000,  -- 8:00 AM
    @weekday_pager_end_time = 180000,   -- 6:00 PM
    @saturday_pager_start_time = 80000, 
    @saturday_pager_end_time = 180000, 
    @sunday_pager_start_time = 90000,   -- 9:00 AM
    @sunday_pager_end_time = 180000, 
    @pager_days = 126,                  -- Days of the week mask
    @email_address = N'amin@mesbahi.net', 
    @category_name = N'[Uncategorized]';
GO

-------------------------------------------------
-- Region: 5. Querying SQL Server Agent Jobs
-------------------------------------------------
/*
  5.1 Retrieve a list of all jobs.
*/
SELECT 
    job_id, 
    [name] 
FROM msdb.dbo.sysjobs;
GO

/*
  5.2 Retrieve detailed information for jobs currently running on the server.
*/
SELECT 
    job.[name] AS JobName,
    job.enabled,
    job.description,
    step.step_name,
    step.command,
    js.server,
    step.database_name
FROM msdb.dbo.sysjobs AS job
INNER JOIN msdb.dbo.sysjobsteps AS step ON job.job_id = step.job_id
INNER JOIN msdb.dbo.sysjobservers AS js ON job.job_id = js.job_id;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
