DOCS: 
* https://roble.openlab.uninorte.edu.co/docs/database
* https://roble.openlab.uninorte.edu.co/docs/database/records
* https://roble.openlab.uninorte.edu.co/docs/autenticacion
* https://roble.openlab.uninorte.edu.co/docs/database/types


Table Name: evaluation_items

NAME DATATYPE FORMAT
_id character varying varchar
evaluationId character varying varchar
criterionKey character varying varchar
criterionLabel character varying varchar
score numeric numeric
maxScore numeric numeric
weight numeric numeric



Table Name: csv_imports

NAME DATATYPE FORMAT
_id - character varying - varchar
courseId - character varying - varchar
categoryId - character varying - varchar
uploadedBy - character varying - varchar
uploadedAt - timestamp with time zone - timestamptz
fileHash - character varying - varchar
status - character varying - varchar



Table Name: Registro_db

NAME DATATYPE FORMAT
_id - character varying - varchar
email - character varying - varchar
name - character varying - varchar
role - character varying - varchar



Table Name: users

NAME DATATYPE FORMAT
_id - character varying - varchar
name - character varying - varchar
rol - character varying - varchar
email - character varying - varchar
uid - character varying - varchar



Table Name: evaluation_cycles

NAME DATATYPE FORMAT
_id - character varying - varchar
courseId - character varying - varchar
categoryId - character varying - varchar
title - character varying - varchar
openedBy - character varying - varchar
openedAt - timestamp with time zone - timestamptz
closeAt - timestamp with time zone - timestamptz
status - character varying - varchar
criteria - json - json
groupId - character varying - varchar



Table Name: groups

NAME DATATYPE FORMAT
_id - character varying - varchar
categoryId - character varying - varchar
courseId - character varying - varchar
groupName - character varying - varchar
displayName - character varying - varchar
nrc - character varying - varchar
createdAt - timestamp with time zone - timestamptz



Table Name: courses

NAME DATATYPE FORMAT
_id - character varying - varchar
name - character varying - varchar
nrc - character varying - varchar
term - character varying - varchar
createdBy - character varying - varchar
createdAt - timestamp with time zone - timestamptz



Table Name: group_categories

NAME DATATYPE FORMAT
_id - character varying - varchar
courseId - character varying - varchar
name - character varying - varchar
createdAt - timestamp with time zone - timestamptz



Table Name: evaluations

NAME DATATYPE FORMAT
_id - character varying - varchar
cycleId - character varying - varchar
evaluatorUid - character varying - varchar
evaluateeUid - character varying - varchar
comments - text - text
createdAt - timestamp with time zone - timestamptz
updatedAt - timestamp with time zone - timestamptz
evaluatorGroupIdAtEval - character varying - varchar
evaluateeGroupIdAtEval - character varying - varchar
enrollmentIdAtEval - character varying - varchar
results - json - json



Table Name: enrollments

NAME DATATYPE FORMAT
_id - character varying - varchar
groupId - character varying - varchar
studentUId - character varying - varchar
studentName - character varying - varchar
studentEmail - character varying - varchar
enrolledAt - timestamp without time zone - timestamp
isActive - boolean - bool
validFrom - timestamp with time zone - timestamptz
validTo - timestamp with time zone - timestamptz
sourceImportId - character varying - varchar