module UserFilesHelper
  #Se miran los iconos disponibles en el directorio public/images/file_icons/16px. Si el fichero tiene una extensión
  #cuyo icono existe se devuelve, en caso contrario se devuelve _blank que es un icono genérico
  def fileType(name)
    knownTypes = ['aac', 'ai', 'aiff', 'avi', 'bmp', 'c', 'cpp', 'css', 'dat', 'dir', 'dmg', 'doc', 'dotx', 'dwg',
      'dxf', 'eps', 'exe', 'flv', 'gif', 'h', 'hpp', 'html', 'ics', 'iso', 'java', 'jpeg', 'jpg', 'key', 'mid',
      'mp3', 'mp4', 'mpg', 'odf', 'ods', 'odt', 'odp', 'otp', 'ots', 'ott', 'pdf', 'php', 'png', 'ppt', 'psd',
      'py', 'qt', 'rar', 'rb', 'rtf', 'sql', 'tga', 'tgz', 'tiff', 'txt', 'wav', 'xls', 'xlsx', 'xml', 'yml', 'zip']
    splitName = name.split('.')
    if (splitName.size < 2)
      return "_blank"
    else
      if (knownTypes.include? splitName[-1])
        return splitName[-1]
      else
        return "_blank"
      end
    end
  end

  def formatAvailableStorage(bytes)
    size = bytes/1024
    if (size <= 0)
      size = "0 MB"
    elsif (size >= 1024)
      size = (size/1024).to_s + "MB"
    else
      size = size.to_s + "KB"
    end
  end

  def jsSearchFormValidation
    javascript_tag <<-EOS
      function validate(form) {
        var res = true;

        if (isNaN(form.minSize.value)) {
          Element.show("minSize_NaN");
          Element.hide("min_sup_max");
          form.minSize.up(0).setAttribute("class","field_with_errors");
          res = false;
        }
        if (isNaN(form.maxSize.value)) {
          Element.show("maxSize_NaN");
          Element.hide("min_sup_max");

          form.maxSize.up(0).setAttribute("class","field_with_errors");
          res = false;
        }
         if ((form.minSize.value > form.maxSize.value) && !isNaN(form.minSize.value) && !isNaN(form.maxSize.value))  {
          Element.show("min_sup_max");
          Element.hide("maxSize_NaN");
          Element.hide("minSize_NaN");
          form.maxSize.up(0).setAttribute("class","field_with_errors");
          form.minSize.up(0).setAttribute("class","field_with_errors");
          res = false;
        }
        return res;
      }
    EOS
  end

  def jsValidationDirectories
    javascript_tag <<-EOS
    function validateLength(form) {
      var res = true;
      //alert("What!");
      if (form.name.value.length < 1){
        form.name.up(0).setAttribute('class',"field_with_errors");
        form.name.up(0).setAttribute('style',"float: left");
        form.down("div.errors_for").setAttribute('style','display: inline');
        res = false;
      }

    return res;
    }
    EOS
  end

end
