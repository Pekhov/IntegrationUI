/**
 * Created by PekAV on 21.12.2017.
 */
/**
function changeText(name, host, port, user, password)
{
    document.getElementById('mq_attributes_queue').value = name;
    document.getElementById('mq_attributes_host').value = host;
    document.getElementById('mq_attributes_port').value = port;
    document.getElementById('mq_attributes_user').value = user;
    document.getElementById('mq_attributes_password').value = password;
}
 */
function send_alert(message)
{
    alert(message);
}
function get_form_data()
{
    form_xml = document.getElementById("xml_text_field").value;
    form_product = document.getElementById("xml_product_name").value;
    form_category = document.getElementById("xml_select_category_name").value;
    form_xml_name = document.getElementById("xml_xml_name").value;
    form_xml_selected_name = document.getElementById("xml_select_xml_name").value;
    return {
        form_xml: form_xml,
        form_product: form_product,
        form_category: form_category,
        form_xml_name: form_xml_name,
        form_xml_selected_name: form_xml_selected_name
    };
}
function addElement(text)
{
    $('#list').html(text);
}
function Base64(coding_mode){
    textarea = document.getElementById("xml_text_field");
    selection = (textarea.value).substring(textarea.selectionStart,textarea.selectionEnd);
    if (coding_mode == "encode"){
        selectionEncode = window.btoa(unescape(encodeURIComponent(selection)));
    }
    else if (coding_mode == "decode"){
        selectionEncode = decodeURIComponent(escape(window.atob(selection)));
    }
    else if (coding_mode == "uuid"){
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }
        selectionEncode = s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
    }
    new_text = textarea.value.replace(selection, selectionEncode);
    textarea.value = new_text;
}
function getSelectedId() {
    textarea = document.getElementById("xml_text_field");
    selection = (textarea.value).substring(textarea.selectionStart,textarea.selectionEnd);
    $.ajax({
        url: "/xml_sender/changeId",
        type: "POST",
        data: { changeXml: { tag: selection, xml: textarea.value } },
    });
}
function updateDiv()
{
    $( "#list" ).load(window.location.href + " #list" );
}
function test_call()
{
    $.ajax({
        url: "/xml_sender/tester",
        type: "POST",
        remote: false,
        data: { product: { name: "Filip", description: "whatever" } },
    });
}
$(function() {
    $.contextMenu({
        selector: '.context-menu-one',
        callback: function(key, options) {
            form_elements = get_form_data();
            if (key == 'new'){
                $.ajax({
                    url: "xml_sender/create_xml",
                    type: "POST",
                    dataType: "script",
                    data: { form_elements: {
                        xml_text: form_elements.form_xml,
                        category_id: form_elements.form_category,
                        form_product: form_elements.form_product,
                        xml_name: form_elements.form_xml_name
                        } },
                });
            }
            if (key == 'delete'){
                $.ajax({
                    url: "xml_sender/delete_xml",
                    type: "POST",
                    dataType: "script",
                    data: { form_elements: {
                            xml_text: form_elements.form_xml,
                            category_id: form_elements.form_category,
                            form_product: form_elements.form_product,
                            xml_name: form_elements.form_xml_name,
                            id: form_elements.form_xml_selected_name
                        } },
                });
            }
            if (key == 'edit'){
                $.ajax({
                    url: "xml_sender/edit_xml",
                    type: "POST",
                    dataType: "script",
                    data: { form_elements: {
                            xml_text: form_elements.form_xml,
                            category_id: form_elements.form_category,
                            form_product: form_elements.form_product,
                            xml_name: form_elements.form_xml_name,
                            id: form_elements.form_xml_selected_name
                        } },
                });
            }

        },
        items: {
            "save": {name: "Сохранить изменения", icon: "edit"},
            "new": {name: "Сохранить,как новую", icon: "edit"},
            "edit": {name: "Редактировать", icon: "edit"},
            "delete": {name: "Удалить", icon: "delete"},
        }
    });
});