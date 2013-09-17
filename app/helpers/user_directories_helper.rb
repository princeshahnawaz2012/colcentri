module UserDirectoriesHelper
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
