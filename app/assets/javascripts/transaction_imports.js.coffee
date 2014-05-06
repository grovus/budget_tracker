# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->

  numChecked = () ->
    len = $('.transaction_checkboxes:checked').length
    console.log(len)
    $('input[value="Edit Checked"]').prop('disabled', len == 0)
    $('input[value="Delete Checked"]').prop('disabled', len == 0)

  # ------------------------------------------------------
  # pretty-fy the upload field
  # ------------------------------------------------------
  $realInputField = $('#transaction_import_file_name')

  # drop just the filename in the display field
  $realInputField.change ->
    $('#file-display').val $(@).val().replace(/^.*[\\\/]/, '')

  # trigger the real input field click to bring up the file selection dialog
  $('#upload-btn').click ->
    $realInputField.click()

  $('#Select_All').click ->
    $('.transaction_checkboxes').prop('checked', $(this).prop('checked'))
    numChecked()

  $('.transaction_checkboxes').change ->
  	if (!$(this).prop('checked'))
  	  $('#Select_All').prop('checked', false)
  	numChecked()
