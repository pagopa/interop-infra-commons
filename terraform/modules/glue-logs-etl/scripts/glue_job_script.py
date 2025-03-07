import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import gs_extract_json

args = getResolvedOptions(sys.argv, [
    'JOB_NAME', 
    'destination_s3_bucket', 
    'glue_database', 
    'glue_table', 
    'predicate'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

glue_database = args['glue_database']
glue_table = args['glue_table']
predicate = args['predicate']
destination_s3_bucket = args['destination_s3_bucket']

# Script generated for node Amazon S3
AmazonS3_source_node = glueContext.create_dynamic_frame.from_catalog(
    database=glue_database, 
    table_name=glue_table, 
    push_down_predicate=predicate, 
    transformation_ctx="AmazonS3_source_node"
)

# Script generated for node Select Fields
SelectFields_node1741103889300 = SelectFields.apply(
    frame=AmazonS3_source_node, 
    paths=["message", "year", "month", "day"], 
    transformation_ctx="SelectFields_node1741103889300"
)

# Script generated for node Extract JSON Path
ExtractJSONPath_node1741250448461 = SelectFields_node1741103889300.gs_extract_json(
    colName="message", 
    jsonPaths="log,pod_app,pod_namespace,stream", 
    colList="log, pod_app, pod_namespace, stream", 
    dropCol=True
)

# Script generated for node Amazon S3
AmazonS3_destination_node = glueContext.write_dynamic_frame.from_options(
    frame=ExtractJSONPath_node1741250448461, 
    connection_type="s3", 
    format="json", 
    connection_options={
        "path": f"s3://{destination_s3_bucket}", 
        "compression": "gzip", 
        "partitionKeys": ["year", "month", "day"]
    }, 
    transformation_ctx="AmazonS3_destination_node")

job.commit()