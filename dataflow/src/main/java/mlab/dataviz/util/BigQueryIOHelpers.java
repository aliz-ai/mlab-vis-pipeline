package mlab.dataviz.util;

import org.apache.beam.sdk.io.gcp.bigquery.BigQueryIO;
import org.apache.beam.sdk.values.PCollection;
import org.apache.beam.sdk.values.PDone;

import com.google.api.services.bigquery.model.TableRow;
import com.google.api.services.bigquery.model.TableSchema;
import com.google.cloud.bigquery.JobInfo.CreateDisposition;
import com.google.cloud.bigquery.JobInfo.WriteDisposition;

public class BigQueryIOHelpers {

	/**
	 * Helper to write to a BigQuery table
	 * @param rows
	 * @param outputTable
	 * @param outputSchema
	 * @param writeDisposition
	 * @param createDisposition
	 * @return
	 */
	public static PDone writeTable(PCollection<TableRow> rows, String outputTable, 
			TableSchema outputSchema, WriteDisposition writeDisposition, 
			CreateDisposition createDisposition) {
		return rows.apply("Write " + outputTable, BigQueryIO.write()
			.to(outputTable)
			.withSchema(outputSchema)
			.withWriteDisposition(writeDisposition)
			.withCreateDisposition(createDisposition));
	}
}
