
/**
 * Dynamically create form and submit.
 *
 * Author: AAV
 */
export default function downloadSQLQUERY(sequence_ids, job_id) {
    var form = $('<form/>').attr('method', 'post').attr('action', 'get_sqlquery');
    addField('sequence_ids', sequence_ids);
    addField('job_id', job_id);
    console.log('sequence_ids in dnld fasta',sequence_ids)
    console.log('job_id in dnld fasta',job_id)
    form.appendTo('body').submit().remove();

    function addField(name, val) {
        form.append(
            $('<input>').attr('type', 'hidden').attr('name', name).val(val)
        );
    }
}