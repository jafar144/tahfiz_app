import 'package:khoirunnasyien/core/config/app_config.dart';

class MessageUtils {
  static String getPaymentReminderMessage(
    String name,
    String nis,
    String monthYear,
  ) {
    return """Assalamualaikum warohmatullahi wabarokatuh

    Sehubungan akan berakhirnya bulan $monthYear

    Kami hanya mengingatkan..!

    Menurut catatan bendahara lembaga kami, bahwa anak Bapak/Ibu:
    Nama: $name
    NIS: $nis

    belum melunasi SPP $monthYear

    Silahkan cek spp anak di aplikasi.

    Mohon kerjasamanya, tunggakan tersebut agar segera diselesaikan.

    ${AppConfig.current.payment.transferInstruction}

    Atas kerjasamanya, terima kasih

    #Mohon koreksi bila data kami salah""";
  }
}
