document.on('ajax:success', '.colcentric_data a[data-method="delete"]', function(e, link) {
  link.up('.colcentric_data').remove();
})
