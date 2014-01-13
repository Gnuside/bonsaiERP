@_b =
  numSeparator: ','
  numDelimiter: '.'
  numPresicion: 2
  currencyDefaults: {'separator': @numSeparator, 'delimiter': @numDelimiter, 'precision': @numPresicion}
  #
  dateFormat: (date, format) ->
    format = format || $.datepicker._defaults.dateFormat
    if date
      d = $.datepicker.parseDate('yy-mm-dd', date )
      $.datepicker.formatDate($.datepicker._defaults.dateFormat, d)
    else
      ""
  # Returns the value with decimals
  roundVal: (val, dec) ->
    dec or= 0
    if dec is 0
      Math.round(val)
    else
      Math.round(val * Math.pow(10, dec)) / Math.pow(10, dec)

  # ntc similar function to Ruby on rails number_to_currency
  # @param [String, Decimal, Integer] val
  ntc: (val, precision) ->
    precision = if precision >= 0 then precision else @numPresicion

    val = if typeof val is 'string' then (1 * val) else val

    if val < 0 then sign = "-" else sign = ""

    vals = val.toFixed(precision).replace(/^-/, "").split(".")
    val = vals[0]
    l = val.length - 1
    ar = val.split("")
    arr = []
    tmp = ""
    c = 0
    for i in [l..0]
      tmp = ar[i] + tmp
      if (l - i + 1)%3 is 0 and i < l
        arr.push(tmp)
        tmp = ''
      c++

    t = arr.reverse().join(@numDelimiter)
    if tmp isnt ""
      sep = if t.length > 0 then @numDelimiter else ""
      t = tmp + sep + t

    if precision is 0
      sign + t
    else
      sign + t + @numSeparator + vals[1]
  # Set the global variable

  # presents the dimesion in bytes
  toByteSize: (bytes, dec) ->
    dec ||= @numPresicion
    switch true
      when bytes < 1024 then bytes + " bytes"
      when bytes < Math.pow(1024, 2) then @ntc( bytes/Math.pow(1024, 1) ) + " Kb"
      when bytes < Math.pow(1024, 3) then @ntc( bytes/Math.pow(1024, 2) ) + " MB"
      when bytes < Math.pow(1024, 4) then @ntc( bytes/Math.pow(1024, 3) ) + " GB"
      when bytes < Math.pow(1024, 5) then @ntc( bytes/Math.pow(1024, 4) ) + " TB"
      when bytes < Math.pow(1024, 6) then @ntc( bytes/Math.pow(1024, 5) ) + " PB"
      else
        roundVal( bytes/ Math.pow(1024, 6)) + " EB"

  notEnter: (event) ->
    ( event.type is "keyup" or event.type is "keypress" ) and event.keyCode isnt 13

  # creates Image tag
  createImagetag: (path, image, options = {}) ->
    if(image)
      options = $.extend(options, {src: path})
      $img = $('<img />').attr(options)

      $('<div/>').append( $img ).html()
    else
      ext = path.replace(/\?[0-9]+$/, '').split(".")
      ext = "." + ext[ext.length - 1].toLowerCase()
      options = $.extend(options, {src: @getExtnameImage( ext )})

      img = $('<img />').attr(options)
      $('<div/>').append( img ).html()

  # Returns an image with the correct file extension
  getExtnameImage: (file) ->
    file = file.split('.')
    ext = file[file.length - 1]
    switch ext.toLowerCase()
      when "pdf" then return "/assets/pdf.png"
      when "xls", "xlsx", "xlsm" then return "/assets/excel.png"
      when "doc", "docx" then return "/assets/word.png"
      when "html", "htm" then return "/assets/html.png"
      when "pps", "ppt", "pptx" then return "/assets/powerpoint.png"
      when "psd" then return "/assets/photoshop.png"
      else "/assets/file.png"

  # Function to determine background colors
  idealTextColor: (bgColor) ->

    nThreshold = 105
    components = @getRGBComponents(bgColor)
    bgDelta = (components.R * 0.299) + (components.G * 0.587) + (components.B * 0.114)

    if ((255 - bgDelta) < nThreshold) then "#000000" else "#ffffff"

  getRGBComponents: (color) ->

    r = color.substring(1, 3)
    g = color.substring(3, 5)
    b = color.substring(5, 7)

    {
       R: parseInt(r, 16),
       G: parseInt(g, 16),
       B: parseInt(b, 16)
    }

  currencyLabel: (val) ->
    if val?
      ['<span class="label bg-black" title=',
        '"', currencies[val]['name'], '"', ' data-toggle="tooltip">',
        val, '</span>'].join('')

  nl2br: (val) ->
    val.toString().replace(/\n/g, '<br>')

  isNumber: (val) ->
    not(isNaN(val)) and isFinite(val)
