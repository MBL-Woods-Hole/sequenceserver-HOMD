
/**
 * Dynamically create form and submit.
 *
 * Author: AAV
 */
export default function downloadSQLQUERY(sequence_ids) {
    var form = $('<form/>').attr('method', 'post').attr('action', 'get_sqlquery');
    addField('sequence_ids', sequence_ids);
    console.log('sequence_ids in dnld fasta',sequence_ids)
    form.appendTo('body').submit().remove();

    function addField(name, val) {
        form.append(
            $('<input>').attr('type', 'hidden').attr('name', name).val(val)
        );
    }
}