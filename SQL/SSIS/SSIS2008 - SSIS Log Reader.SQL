WITH 
  LOG_SUBSET AS
  (
    SELECT TOP 1000 id, REPLACE(event, 'User:', '') AS event, starttime, source, message
      FROM sysssislog
      ORDER BY id DESC
  ),
  ORDERED_LOG_SUBSET AS
  (
    SELECT TOP 1000 id, event, starttime, source, message 
      FROM LOG_SUBSET
      ORDER BY id
  ),
  EVENTTYPED_LOG AS
  (
    SELECT id, event, starttime, source, message,
      HASHBYTES('SHA1', CAST(starttime AS CHAR(20)) + event + message) AS eventtype_group_key
    FROM ORDERED_LOG_SUBSET
  ),
  CONTIGUOUS_EVENT_GROUPED_LOG AS
  (
    SELECT id, event, starttime, source, message, eventtype_group_key, 
      ROW_NUMBER() OVER (ORDER BY id) AS s1,
      ROW_NUMBER() OVER (PARTITION BY eventtype_group_key ORDER BY id) AS s2,
      ROW_NUMBER() OVER (ORDER BY id) - ROW_NUMBER() OVER (PARTITION BY eventtype_group_key ORDER BY id) AS sequence
    FROM EVENTTYPED_LOG
  ),
  GROUPED_LOG AS
  (
    SELECT id, event, starttime, source, message, eventtype_group_key, s1, s2, sequence,
      HASHBYTES('SHA1', CAST(eventtype_group_key AS CHAR(36)) + CAST(sequence AS CHAR(10))) AS event_group
    FROM CONTIGUOUS_EVENT_GROUPED_LOG
  )SELECT MIN(id) AS id, event, starttime, message,
    SUBSTRING(REPLACE(REPLACE(
      (
        SELECT ' < ' + source
           FROM GROUPED_LOG AS Y
          WHERE X.event_group = Y.event_group
          GROUP BY source
          ORDER BY MIN(id) DESC
            FOR XML PATH('')
      ), 
      '&lt;', '<'), '&amp;', '&'), 3, 2000) AS source_list
  FROM GROUPED_LOG AS X
  GROUP BY event, starttime, message, event_group
  ORDER BY MIN(id)