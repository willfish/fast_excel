module FastExcel
  # Creates internal Libxlsxwriter::Datetime from Datetime object
  def self.lxw_datetime(time)
    date = Libxlsxwriter::Datetime.new
    date[:year] = time.year
    date[:month] = time.month
    date[:day] = time.day
    date[:hour] = time.hour
    date[:min] = time.minute
    date[:sec] = time.second
    date
  end

  # Creates internal Libxlsxwriter::Datetime from Time object
  def self.lxw_time(time)
    date = Libxlsxwriter::Datetime.new
    date[:year] = time.year
    date[:month] = time.month
    date[:day] = time.day
    date[:hour] = time.hour
    date[:min] = time.min
    date[:sec] = time.sec
    date
  end

  def self.lxw_date(value)
    date = Libxlsxwriter::Datetime.new
    date[:year] = value.year
    date[:month] = value.month
    date[:day] = value.day
    date[:hour] = 0
    date[:min] = 0
    date[:sec] = 0
    date
  end

  # seconds in 1 day
  XLSX_DATE_DAY = 86400.0

  # days between 1970-jan-01 and 1900-jan-01
  XLSX_DATE_EPOCH_DIFF = 25569

  # Convert time to number of days, and change beginning point from 1st jan 1970 to 1st jan 1900
  # Offset argument should be number of seconds, if not specified then it will use Time.zone.utc_offset || 0
  #
  # https://support.microsoft.com/en-us/help/214330/differences-between-the-1900-and-the-1904-date-system-in-excel
  def self.date_num(time, offset = nil)
    unless offset
      # Try use value utc_offset
      if time.respond_to?(:utc_offset)
        offset = time.utc_offset
      # Else try use Rails' app timezone
      elsif Time.respond_to?(:zone) && !Time.zone.nil?
        offset = Time.zone.utc_offset
      else
        offset = 0 # rollback to UTC
      end
    end

    time.to_f / XLSX_DATE_DAY + XLSX_DATE_EPOCH_DIFF + offset / XLSX_DATE_DAY
  end
end
