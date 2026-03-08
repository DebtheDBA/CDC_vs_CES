
--DROP EVENT SESSION [Track_CES_Usage] ON SERVER 
--GO

CREATE EVENT SESSION [Track_CES_Usage]
ON SERVER
    ADD EVENT sqlserver.synapse_link_trace,
    ADD EVENT sqlserver.synapse_link_error
    ADD TARGET package0.event_file
    (SET filename = N'C:\XE_Logs\CESTracking.xel')
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = OFF
);
GO

/*
CREATE EVENT SESSION ChangeEventStreaming   ON SERVER
ADD EVENT sqlserver.synapse_link_error   (   )   
ADD TARGET package0.event_file   (SET filename=N'C:\temp\YourSession_Target1.xel');  
GO
*/