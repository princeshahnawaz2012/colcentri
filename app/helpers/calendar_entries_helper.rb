module CalendarEntriesHelper

  def jsNewEntryFormValidation
    javascript_tag <<-EOS
      function validate(form) {
        var res = true;
        var start_date = new Date(form.start_date_year.value, form.start_date_month.value, form.start_date_day.value)
        var end_date = new Date(form.end_date_year.value, form.end_date_month.value, form.end_date_day.value)

        if (form.valid_start_date.checked && start_date > end_date) {
          Element.show(date_error);
          res = false;
        }
        if ((form.title.value == null) || (form.title.value == "")) {
          Element.show(no_name_error);
          form.title.up(0).setAttribute("class", "field_with_errors");
          res = false;
        }

        return res;
      }
    EOS
  end

  def jsActivateStartDate
    javascript_tag <<-EOS
      function activateStartDate(form) {
        if (form.valid_start_date.checked) {
          form.valid_start_date.value = true;
          form.start_date_day.disabled = false;
          form.start_date_month.disabled = false;
          form.start_date_year.disabled = false;
        }
        else {
          form.valid_start_date.value = false;
          form.start_date_day.disabled = true;
          form.start_date_month.disabled = true;
          form.start_date_year.disabled = true;
        }
      }
    EOS
  end

end