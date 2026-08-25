// lib/l10n/app_strings.dart
// Terjemahan teks aplikasi (ID/EN), berbasis peta string sederhana — bukan
// lewat toolchain ARB/gen-l10n bawaan Flutter — supaya mudah ditambah
// bertahap layar demi layar seiring migrasi tiap halaman, tanpa perlu
// menjalankan `flutter gen-l10n` tiap kali ada teks baru. Bahasa aktif
// ditentukan oleh LocaleController (lib/locale_controller.dart).
//
// Cara pakai: `S.t.namaKey` — dipanggil langsung tanpa perlu BuildContext,
// selalu mengikuti bahasa yang SEDANG dipilih saat itu (sama seperti
// AppColors.xxx mengikuti mode gelap/terang).
//
// Baru mencakup layar Beranda (home_screen.dart) untuk iterasi pertama ini.
// Layar lain (Transaksi, Anggaran, Laporan, dst) masih berbahasa Indonesia
// tetap dan akan menyusul migrasinya satu per satu.
import '../locale_controller.dart';

class AppStrings {
  AppStrings._();

  static AppStringsData get t =>
      LocaleController.instance.isEnglish ? _en : _id;
}

/// Alias pendek — dipakai sebagai `S.t.xxx` di seluruh layar.
typedef S = AppStrings;

class AppStringsData {
  const AppStringsData({
    required this.appName,
    required this.languageSwitchTooltip,
    required this.languageIndonesian,
    required this.languageEnglish,
    required this.home,
    required this.errorLoadData,
    required this.noCashAccountYet,
    required this.noCategoryYet,
    required this.addTransactionTooltip,
    required this.lightMode,
    required this.darkMode,
    required this.backupRestoreTooltip,
    required this.helpTooltip,
    required this.logoutTooltip,
    required this.menuTransactions,
    required this.menuAssets,
    required this.menuBudget,
    required this.menuReportsFull,
    required this.menuReportsShort,
    required this.totalNetAssets,
    required this.statCash,
    required this.statFixedAssets,
    required this.statInvestments,
    required this.statActiveDebt,
    required this.financialRatios,
    required this.ratioCashInvestToDebt,
    required this.ratioTotalAssetsToDebt,
    required this.ratioDebtToAsset,
    required this.noDebt,
    required this.budgetThisMonth,
    required this.budgetNotSetYet,
    required this.recentTransactions,
    required this.viewAll,
    required this.noTransactionsYet,
    // --- Transaksi (transactions_screen.dart) ---
    required this.cancel,
    required this.delete,
    required this.dialogDeleteTransactionTitle,
    required this.deleteTransactionFailed,
    required this.assetsDebtTooltip,
    required this.moreMenuTooltip,
    required this.statIncome,
    required this.statExpense,
    required this.statBalance,
    required this.historySectionTitle,
    required this.viewInvoiceTooltip,
    required this.payDebtPrefix,
    required this.invoiceMaxSizeError,
    required this.ocrFoundAmount,
    required this.ocrFoundDate,
    required this.ocrFoundVendor,
    required this.ocrFoundPrefix,
    required this.ocrFoundSuffix,
    required this.ocrNotFound,
    required this.ocrFailed,
    required this.categoryFallbackName,
    required this.amountInvalid,
    required this.transactionNameRequired,
    required this.invoiceSavedLocallyFailed,
    required this.saveTransactionFailed,
    required this.editTransactionTitle,
    required this.addTransactionTitle,
    required this.scanInvoiceOptional,
    required this.takePhoto,
    required this.gallery,
    required this.readingInvoice,
    required this.invoiceLocalDisclosure,
    required this.amountFieldLabel,
    required this.transactionNameFieldLabel,
    required this.categoryLabel,
    required this.manageCategoryLink,
    required this.oldCategorySuffix,
    required this.dateFieldLabel,
    required this.cashAccountLabel,
    required this.manageAccountLink,
    required this.linkToDebtLabel,
    required this.notLinked,
    required this.remainingPrefix,
    required this.noteFieldLabel,
    required this.saveChanges,
    required this.addButton,
    // --- Aset, Investasi & Utang (accounts_assets_screen.dart) ---
    required this.assetsDebtScreenTitle,
    required this.tabCashAccounts,
    required this.tabDebts,
    required this.totalCash,
    required this.sectionCashBank,
    required this.totalFixedAssets,
    required this.noFixedAssetsYet,
    required this.updateValueButton,
    required this.totalInvestments,
    required this.noInvestmentsYet,
    required this.totalActiveDebt,
    required this.debtsInstallments,
    required this.manageDebtLink,
    required this.noActiveDebtYet,
    required this.perMonthSuffix,
    required this.deleteAccountFailed,
    required this.deleteAssetFailed,
    required this.deleteInvestmentFailed,
    required this.accountNameRequired,
    required this.addAccountFailed,
    required this.addAccountTitle,
    required this.accountNameFieldHint,
    required this.accountTypeLabel,
    required this.assetNameRequired,
    required this.assetValueInvalid,
    required this.addAssetFailed,
    required this.addAssetTitle,
    required this.assetNameFieldHint,
    required this.assetTypeLabel,
    required this.currentValueEstimateLabel,
    required this.valueInvalid,
    required this.updateValueFailed,
    required this.currentlyPrefix,
    required this.newValueEstimateLabel,
    // --- Anggaran (budgets_screen.dart) ---
    required this.budgetScreenTitle,
    required this.saveBudgetFailed,
    required this.noCategoryYetBudget,
    required this.totalRealizationThisMonth,
    // --- Kategori (categories_screen.dart) ---
    required this.categoryScreenTitle,
    required this.tabExpenseCategory,
    required this.tabIncomeCategory,
    required this.categoryNameRequired,
    required this.addCategoryFailed,
    required this.updateCategoryFailed,
    required this.deleteCategoryInUse,
    required this.expenseCategoryDescription,
    required this.incomeCategoryDescription,
    required this.newExpenseCategoryHint,
    required this.newIncomeCategoryHint,
    required this.noExpenseCategoryYet,
    required this.noIncomeCategoryYet,
    required this.editButton,
    // --- Laporan (reports_screen.dart) ---
    required this.tabFinancialReport,
    required this.tabFinancialHealth,
    required this.fromLabel,
    required this.toLabel,
    required this.typeLabel,
    required this.filterAll,
    required this.clearCategoryFilter,
    required this.statBalanceNet,
    required this.categoryBreakdownTitle,
    required this.noDataInRange,
    required this.noTransactionInRange,
    required this.debtInstallmentSummaryTitle,
    required this.remainingDebt,
    required this.installmentPerMonth,
    required this.financialRatiosCurrentTitle,
    required this.ratioCashInvestDebtFull,
    required this.ratioCashInvestAssetDebtFull,
    required this.ratioDebtToAssetFull,
    required this.debtToAssetExplanation,
    // --- Kesehatan Keuangan (health_screen.dart) ---
    required this.savingsRatioLabel,
    required this.emergencyFundLabel,
    required this.budgetDisciplineLabel,
    required this.debtToIncomeLabel,
    required this.noIncomeDataThisMonth,
    required this.notEnoughExpenseData3Months,
    required this.noBudgetSetYet,
    required this.savingsAdviceGood,
    required this.savingsAdviceWarn,
    required this.savingsAdviceBad,
    required this.emergencyAdviceGood,
    required this.emergencyAdviceWarn,
    required this.emergencyAdviceBad,
    required this.disciplineAdviceGood,
    required this.disciplineAdviceWarn,
    required this.disciplineAdviceBad,
    required this.debtRatioAdviceGood,
    required this.debtRatioAdviceWarn,
    required this.debtRatioAdviceBad,
    required this.notEnoughDataForScore,
    required this.healthScoreTitle,
    required this.healthy,
    required this.fairlyHealthy,
    required this.needsAttention,
    // --- Utang (debts_screen.dart) ---
    required this.deleteDebtFailed,
    required this.totalRemainingDebt,
    required this.noDebtYet,
    required this.paidOffSuffix,
    required this.recordPaymentButton,
    required this.debtNameRequired,
    required this.principalTotalInvalid,
    required this.monthlyInstallmentInvalid,
    required this.addDebtFailed,
    required this.addDebtTitle,
    required this.debtNameFieldHint,
    required this.debtTypeLabel,
    required this.principalTotalLabel,
    required this.monthlyInstallmentLabel,
    required this.startDateLabel,
    required this.paymentAmountInvalid,
    required this.recordPaymentFailed,
    required this.currentRemainingPrefix,
    required this.paymentAmountLabel,
    required this.payButton,
    // --- Backup & Pulihkan (backup_screen.dart) ---
    required this.unknownLabel,
    required this.confirmRestoreTitle,
    required this.restoreButton,
    required this.creatingBackup,
    required this.backupCreatedSuccess,
    required this.readingBackupFile,
    required this.restoringData,
    required this.restoreSuccess,
    required this.processingLabel,
    required this.createBackupTitle,
    required this.createBackupDescription,
    required this.createSaveBackupTitle,
    required this.createSaveBackupSubtitle,
    required this.restoreFromBackupTitle,
    required this.restoreDescription,
    required this.chooseBackupFileTitle,
    required this.chooseBackupFileSubtitle,
    required this.passphraseMinLength,
    required this.passphraseMismatch,
    required this.createPassphraseTitle,
    required this.passphraseWarning,
    required this.passphraseLabel,
    required this.repeatPassphraseLabel,
    required this.includeAttachmentsTitle,
    required this.includeAttachmentsSubtitleOn,
    required this.includeAttachmentsSubtitleOff,
    required this.continueButton,
    required this.enterPassphraseTitle,
    // --- Bantuan (help_screen.dart) ---
    required this.quickGuideTitle,
    required this.quickGuideSubtitle,
    required this.viewIntroTutorialAgain,
    required this.privacyPolicyLink,
    required this.termsLink,
    required this.deleteAccountLink,
    required this.helpDarkModeTitle,
    required this.helpTxPoint1,
    required this.helpTxPoint2,
    required this.helpTxPoint3,
    required this.helpTxPoint4,
    required this.helpAssetPoint1,
    required this.helpAssetPoint2,
    required this.helpAssetPoint3,
    required this.helpAssetPoint4,
    required this.helpBudgetPoint1,
    required this.helpBudgetPoint2,
    required this.helpBudgetPoint3,
    required this.helpBudgetPoint4,
    required this.helpReportPoint1,
    required this.helpReportPoint2,
    required this.helpReportPoint3,
    required this.helpDarkModePoint1,
    required this.helpDarkModePoint2,
    // --- Hapus Akun (delete_account_screen.dart) ---
    required this.areYouSureTitle,
    required this.deleteAccountConfirmBody,
    required this.deleteAccountFailedGeneric,
    required this.dangerZoneTitle,
    required this.dangerZoneDescription,
    required this.deleteConfirmWord,
    required this.deleteAccountAndAllDataButton,
    // --- Login (login_screen.dart) ---
    required this.signInToContinue,
    required this.emailLabel,
    required this.passwordLabel,
    required this.genericConnectionError,
    required this.signInButton,
    required this.orDivider,
    required this.signInWithGoogle,
    required this.googleConsentPrefix,
    required this.googleConsentMiddle,
    required this.googleConsentSuffix,
    required this.noAccountYetPrefix,
    // --- Daftar (register_screen.dart) ---
    required this.registerTitle,
    required this.registerSubtitle,
    required this.yourNameLabel,
    required this.householdNameLabel,
    required this.householdNameHint,
    required this.agreeConsentPrefix,
    required this.agreeConsentSuffix,
    required this.mustAgreeError,
    required this.registerButton,
    required this.registerSuccessMessage,
    required this.registerFailedGeneric,
    required this.alreadyHaveAccountPrefix,
    // --- Detail Transaksi (transaction_detail_screen.dart) ---
    required this.transactionDetailTitle,
    required this.transactionNameLabel,
    required this.debtLinkLabel,
    required this.noteLabel,
    required this.invoicePhotoLabel,
    required this.failedLoadPhoto,
    required this.failedLoadInvoicePhoto,
    // --- Investasi (investments_screen.dart) ---
    required this.investmentNameRequired,
    required this.initialCapitalInvalid,
    required this.addInvestmentFailed,
    required this.addInvestmentTitle,
    required this.investmentNameLabel,
    required this.investmentTypeLabel,
    required this.initialCapitalLabel,
    required this.currentValueEmptyLabel,
    required this.currentValueLabel,
    // --- Onboarding (onboarding_screen.dart) ---
    required this.onboardWelcomeTitle,
    required this.onboardWelcomeDesc,
    required this.onboardTxTitle,
    required this.onboardTxDesc,
    required this.onboardAssetsDesc,
    required this.onboardBudgetTitle,
    required this.onboardBudgetDesc,
    required this.onboardHealthTitle,
    required this.onboardHealthDesc,
    required this.skipButton,
    required this.startNowButton,
    required this.nextButton,
  });

  final String appName;
  final String languageSwitchTooltip;
  final String languageIndonesian;
  final String languageEnglish;
  final String home;
  final String errorLoadData;
  final String noCashAccountYet;
  final String noCategoryYet;
  final String addTransactionTooltip;
  final String lightMode;
  final String darkMode;
  final String backupRestoreTooltip;
  final String helpTooltip;
  final String logoutTooltip;
  final String menuTransactions;
  final String menuAssets;
  final String menuBudget;
  final String menuReportsFull;
  final String menuReportsShort;
  final String totalNetAssets;
  final String statCash;
  final String statFixedAssets;
  final String statInvestments;
  final String statActiveDebt;
  final String financialRatios;
  final String ratioCashInvestToDebt;
  final String ratioTotalAssetsToDebt;
  final String ratioDebtToAsset;
  final String noDebt;
  final String budgetThisMonth;
  final String budgetNotSetYet;
  final String recentTransactions;
  final String viewAll;
  final String noTransactionsYet;
  // --- Transaksi (transactions_screen.dart) ---
  final String cancel;
  final String delete;
  final String dialogDeleteTransactionTitle;
  final String deleteTransactionFailed;
  final String assetsDebtTooltip;
  final String moreMenuTooltip;
  final String statIncome;
  final String statExpense;
  final String statBalance;
  final String historySectionTitle;
  final String viewInvoiceTooltip;
  final String payDebtPrefix;
  final String invoiceMaxSizeError;
  final String ocrFoundAmount;
  final String ocrFoundDate;
  final String ocrFoundVendor;
  final String ocrFoundPrefix;
  final String ocrFoundSuffix;
  final String ocrNotFound;
  final String ocrFailed;
  final String categoryFallbackName;
  final String amountInvalid;
  final String transactionNameRequired;
  final String invoiceSavedLocallyFailed;
  final String saveTransactionFailed;
  final String editTransactionTitle;
  final String addTransactionTitle;
  final String scanInvoiceOptional;
  final String takePhoto;
  final String gallery;
  final String readingInvoice;
  final String invoiceLocalDisclosure;
  final String amountFieldLabel;
  final String transactionNameFieldLabel;
  final String categoryLabel;
  final String manageCategoryLink;
  final String oldCategorySuffix;
  final String dateFieldLabel;
  final String cashAccountLabel;
  final String manageAccountLink;
  final String linkToDebtLabel;
  final String notLinked;
  final String remainingPrefix;
  final String noteFieldLabel;
  final String saveChanges;
  final String addButton;
  // --- Aset, Investasi & Utang (accounts_assets_screen.dart) ---
  final String assetsDebtScreenTitle;
  final String tabCashAccounts;
  final String tabDebts;
  final String totalCash;
  final String sectionCashBank;
  final String totalFixedAssets;
  final String noFixedAssetsYet;
  final String updateValueButton;
  final String totalInvestments;
  final String noInvestmentsYet;
  final String totalActiveDebt;
  final String debtsInstallments;
  final String manageDebtLink;
  final String noActiveDebtYet;
  final String perMonthSuffix;
  final String deleteAccountFailed;
  final String deleteAssetFailed;
  final String deleteInvestmentFailed;
  final String accountNameRequired;
  final String addAccountFailed;
  final String addAccountTitle;
  final String accountNameFieldHint;
  final String accountTypeLabel;
  final String assetNameRequired;
  final String assetValueInvalid;
  final String addAssetFailed;
  final String addAssetTitle;
  final String assetNameFieldHint;
  final String assetTypeLabel;
  final String currentValueEstimateLabel;
  final String valueInvalid;
  final String updateValueFailed;
  final String currentlyPrefix;
  final String newValueEstimateLabel;
  // --- Anggaran (budgets_screen.dart) ---
  final String budgetScreenTitle;
  final String saveBudgetFailed;
  final String noCategoryYetBudget;
  final String totalRealizationThisMonth;
  // --- Kategori (categories_screen.dart) ---
  final String categoryScreenTitle;
  final String tabExpenseCategory;
  final String tabIncomeCategory;
  final String categoryNameRequired;
  final String addCategoryFailed;
  final String updateCategoryFailed;
  final String deleteCategoryInUse;
  final String expenseCategoryDescription;
  final String incomeCategoryDescription;
  final String newExpenseCategoryHint;
  final String newIncomeCategoryHint;
  final String noExpenseCategoryYet;
  final String noIncomeCategoryYet;
  final String editButton;
  // --- Laporan (reports_screen.dart) ---
  final String tabFinancialReport;
  final String tabFinancialHealth;
  final String fromLabel;
  final String toLabel;
  final String typeLabel;
  final String filterAll;
  final String clearCategoryFilter;
  final String statBalanceNet;
  final String categoryBreakdownTitle;
  final String noDataInRange;
  final String noTransactionInRange;
  final String debtInstallmentSummaryTitle;
  final String remainingDebt;
  final String installmentPerMonth;
  final String financialRatiosCurrentTitle;
  final String ratioCashInvestDebtFull;
  final String ratioCashInvestAssetDebtFull;
  final String ratioDebtToAssetFull;
  final String debtToAssetExplanation;
  // --- Kesehatan Keuangan (health_screen.dart) ---
  final String savingsRatioLabel;
  final String emergencyFundLabel;
  final String budgetDisciplineLabel;
  final String debtToIncomeLabel;
  final String noIncomeDataThisMonth;
  final String notEnoughExpenseData3Months;
  final String noBudgetSetYet;
  final String savingsAdviceGood;
  final String savingsAdviceWarn;
  final String savingsAdviceBad;
  final String emergencyAdviceGood;
  final String emergencyAdviceWarn;
  final String emergencyAdviceBad;
  final String disciplineAdviceGood;
  final String disciplineAdviceWarn;
  final String disciplineAdviceBad;
  final String debtRatioAdviceGood;
  final String debtRatioAdviceWarn;
  final String debtRatioAdviceBad;
  final String notEnoughDataForScore;
  final String healthScoreTitle;
  final String healthy;
  final String fairlyHealthy;
  final String needsAttention;
  // --- Utang (debts_screen.dart) ---
  final String deleteDebtFailed;
  final String totalRemainingDebt;
  final String noDebtYet;
  final String paidOffSuffix;
  final String recordPaymentButton;
  final String debtNameRequired;
  final String principalTotalInvalid;
  final String monthlyInstallmentInvalid;
  final String addDebtFailed;
  final String addDebtTitle;
  final String debtNameFieldHint;
  final String debtTypeLabel;
  final String principalTotalLabel;
  final String monthlyInstallmentLabel;
  final String startDateLabel;
  final String paymentAmountInvalid;
  final String recordPaymentFailed;
  final String currentRemainingPrefix;
  final String paymentAmountLabel;
  final String payButton;
  // --- Backup & Pulihkan (backup_screen.dart) ---
  final String unknownLabel;
  final String confirmRestoreTitle;
  final String restoreButton;
  final String creatingBackup;
  final String backupCreatedSuccess;
  final String readingBackupFile;
  final String restoringData;
  final String restoreSuccess;
  final String processingLabel;
  final String createBackupTitle;
  final String createBackupDescription;
  final String createSaveBackupTitle;
  final String createSaveBackupSubtitle;
  final String restoreFromBackupTitle;
  final String restoreDescription;
  final String chooseBackupFileTitle;
  final String chooseBackupFileSubtitle;
  final String passphraseMinLength;
  final String passphraseMismatch;
  final String createPassphraseTitle;
  final String passphraseWarning;
  final String passphraseLabel;
  final String repeatPassphraseLabel;
  final String includeAttachmentsTitle;
  final String includeAttachmentsSubtitleOn;
  final String includeAttachmentsSubtitleOff;
  final String continueButton;
  final String enterPassphraseTitle;
  // --- Bantuan (help_screen.dart) ---
  final String quickGuideTitle;
  final String quickGuideSubtitle;
  final String viewIntroTutorialAgain;
  final String privacyPolicyLink;
  final String termsLink;
  final String deleteAccountLink;
  final String helpDarkModeTitle;
  final String helpTxPoint1;
  final String helpTxPoint2;
  final String helpTxPoint3;
  final String helpTxPoint4;
  final String helpAssetPoint1;
  final String helpAssetPoint2;
  final String helpAssetPoint3;
  final String helpAssetPoint4;
  final String helpBudgetPoint1;
  final String helpBudgetPoint2;
  final String helpBudgetPoint3;
  final String helpBudgetPoint4;
  final String helpReportPoint1;
  final String helpReportPoint2;
  final String helpReportPoint3;
  final String helpDarkModePoint1;
  final String helpDarkModePoint2;
  // --- Hapus Akun (delete_account_screen.dart) ---
  final String areYouSureTitle;
  final String deleteAccountConfirmBody;
  final String deleteAccountFailedGeneric;
  final String dangerZoneTitle;
  final String dangerZoneDescription;
  final String deleteConfirmWord;
  final String deleteAccountAndAllDataButton;
  // --- Login (login_screen.dart) ---
  final String signInToContinue;
  final String emailLabel;
  final String passwordLabel;
  final String genericConnectionError;
  final String signInButton;
  final String orDivider;
  final String signInWithGoogle;
  final String googleConsentPrefix;
  final String googleConsentMiddle;
  final String googleConsentSuffix;
  final String noAccountYetPrefix;
  final String registerTitle;
  final String registerSubtitle;
  final String yourNameLabel;
  final String householdNameLabel;
  final String householdNameHint;
  final String agreeConsentPrefix;
  final String agreeConsentSuffix;
  final String mustAgreeError;
  final String registerButton;
  final String registerSuccessMessage;
  final String registerFailedGeneric;
  final String alreadyHaveAccountPrefix;
  // --- Detail Transaksi (transaction_detail_screen.dart) ---
  final String transactionDetailTitle;
  final String transactionNameLabel;
  final String debtLinkLabel;
  final String noteLabel;
  final String invoicePhotoLabel;
  final String failedLoadPhoto;
  final String failedLoadInvoicePhoto;
  // --- Investasi (investments_screen.dart) ---
  final String investmentNameRequired;
  final String initialCapitalInvalid;
  final String addInvestmentFailed;
  final String addInvestmentTitle;
  final String investmentNameLabel;
  final String investmentTypeLabel;
  final String initialCapitalLabel;
  final String currentValueEmptyLabel;
  final String currentValueLabel;
  // --- Onboarding (onboarding_screen.dart) ---
  final String onboardWelcomeTitle;
  final String onboardWelcomeDesc;
  final String onboardTxTitle;
  final String onboardTxDesc;
  final String onboardAssetsDesc;
  final String onboardBudgetTitle;
  final String onboardBudgetDesc;
  final String onboardHealthTitle;
  final String onboardHealthDesc;
  final String skipButton;
  final String startNowButton;
  final String nextButton;
}

String typeConfirmWordToConfirm(String word) =>
    LocaleController.instance.isEnglish
    ? 'Type $word to confirm'
    : 'Ketik $word untuk konfirmasi';

String attachmentInfoSuffix(int count) => LocaleController.instance.isEnglish
    ? ', and $count invoice photo attachments'
    : ', dan $count lampiran foto invoice';
String confirmRestoreBody(
  String label,
  int txCount,
  int accCount,
  String attachInfo,
) {
  return LocaleController.instance.isEnglish
      ? 'Backup from $label contains $txCount transactions and $accCount '
            'accounts$attachInfo.\n\nALL of your current household data will '
            'be REPLACED with this backup\'s contents. This action cannot be '
            'undone.'
      : 'Backup dari $label berisi $txCount transaksi dan $accCount '
            'akun$attachInfo.\n\nSELURUH data rumah tangga Anda saat ini akan '
            'DIGANTI dengan isi backup ini. Tindakan ini tidak bisa '
            'dibatalkan.';
}

String backupCreatedWithAttachments(int count) =>
    LocaleController.instance.isEnglish
    ? 'Backup created successfully (including $count attachments).'
    : 'Backup berhasil dibuat (termasuk $count lampiran).';

String confirmDeleteDebtMessage(String name) =>
    LocaleController.instance.isEnglish
    ? 'Delete debt "$name"?'
    : 'Hapus utang "$name"?';
String debtRemainingSummary(
  String remaining,
  String total,
  String installment,
) {
  final suffix = LocaleController.instance.isEnglish ? '/mo' : '/bln';
  return LocaleController.instance.isEnglish
      ? 'Remaining $remaining of $total · $installment$suffix'
      : 'Sisa $remaining dari $total · $installment$suffix';
}

String recordPaymentTitle(String name) => LocaleController.instance.isEnglish
    ? 'Record payment for "$name"'
    : 'Catat pembayaran "$name"';

String savingsDetail(String pct) => LocaleController.instance.isEnglish
    ? "$pct% of this month's income remains as savings."
    : '$pct% dari pemasukan bulan ini tersisa sebagai tabungan.';
String emergencyDetail(String months) => LocaleController.instance.isEnglish
    ? 'Current balance covers $months months of average expenses.'
    : 'Saldo saat ini setara $months bulan pengeluaran rata-rata.';
String disciplineDetail(int under, int total) =>
    LocaleController.instance.isEnglish
    ? '$under of $total budget categories are still under their limit this month.'
    : '$under dari $total kategori anggaran masih di bawah batas bulan ini.';
String debtRatioDetail(String pct) => LocaleController.instance.isEnglish
    ? "Active installments equal $pct% of this month's income."
    : 'Cicilan aktif setara $pct% dari pemasukan bulan ini.';
String outOfScoreLabel(String label) => LocaleController.instance.isEnglish
    ? 'of 100 · $label'
    : 'dari 100 · $label';
String basedOnIndicators(int valid, int total) =>
    LocaleController.instance.isEnglish
    ? 'Based on $valid of $total indicators (not enough data for the rest)'
    : 'Berdasarkan $valid dari $total indikator (data belum cukup untuk sisanya)';

/// "Daftar Transaksi (N)" — perlu interpolasi jumlah.
String transactionListTitle(int count) => LocaleController.instance.isEnglish
    ? 'Transaction List ($count)'
    : 'Daftar Transaksi ($count)';

/// Konfirmasi hapus kategori — perlu interpolasi nama kategori.
String confirmDeleteCategoryMessage(String name) =>
    LocaleController.instance.isEnglish
    ? 'Delete category "$name"?'
    : 'Hapus kategori "$name"?';

/// "Rp X dari Rp Y" pada ringkasan total anggaran — perlu interpolasi.
String spentOfBudgetLabel(String spent, String budget) =>
    LocaleController.instance.isEnglish
    ? '$spent of $budget'
    : '$spent dari $budget';

/// "Terpakai Rp X dari Rp Y" pada progress bar per kategori.
String usedOfBudgetLabel(String spent, String budget) =>
    LocaleController.instance.isEnglish
    ? 'Used $spent of $budget'
    : 'Terpakai $spent dari $budget';

/// Konfirmasi hapus akun/aset/investasi — perlu interpolasi nama, jadi
/// berupa fungsi.
String confirmDeleteAccountMessage(String name) =>
    LocaleController.instance.isEnglish
    ? 'Delete account "$name"?'
    : 'Hapus akun "$name"?';
String confirmDeleteAssetMessage(String name) =>
    LocaleController.instance.isEnglish
    ? 'Delete asset "$name"?'
    : 'Hapus aset "$name"?';
String confirmDeleteInvestmentMessage(String name) =>
    LocaleController.instance.isEnglish
    ? 'Delete investment "$name"?'
    : 'Hapus investasi "$name"?';
String updateAssetValueTitle(String name) => LocaleController.instance.isEnglish
    ? 'Update value for "$name"'
    : 'Perbarui nilai "$name"';

/// Pesan peringatan anggaran terlampaui — perlu interpolasi (nama kategori +
/// nominal terformat), jadi berupa fungsi, bukan field statis biasa.
String budgetExceededMessage(String categoryName, String spent, String budget) {
  return LocaleController.instance.isEnglish
      ? 'This month\'s "$categoryName" budget has been exceeded: $spent of $budget.'
      : 'Anggaran "$categoryName" bulan ini sudah terlampaui: $spent dari $budget.';
}

const _id = AppStringsData(
  appName: 'DompetDigitalKu',
  languageSwitchTooltip: 'Bahasa',
  languageIndonesian: 'Indonesia',
  languageEnglish: 'Inggris',
  home: 'Beranda',
  errorLoadData: 'Gagal memuat data. Tarik ke bawah untuk coba lagi.',
  noCashAccountYet: 'Belum ada akun kas/bank.',
  noCategoryYet: 'Belum ada kategori. Tambah dulu lewat menu Kategori.',
  addTransactionTooltip: 'Tambah transaksi',
  lightMode: 'Mode terang',
  darkMode: 'Mode gelap',
  backupRestoreTooltip: 'Backup & Pulihkan',
  helpTooltip: 'Bantuan & Panduan',
  logoutTooltip: 'Keluar',
  menuTransactions: 'Transaksi',
  menuAssets: 'Aset, Investasi & Utang',
  menuBudget: 'Anggaran',
  menuReportsFull: 'Laporan & Kesehatan Keuangan',
  menuReportsShort: 'Laporan',
  totalNetAssets: 'Total Aset Bersih',
  statCash: 'Kas',
  statFixedAssets: 'Aset Tetap',
  statInvestments: 'Investasi',
  statActiveDebt: 'Utang Aktif',
  financialRatios: 'Rasio Keuangan',
  ratioCashInvestToDebt: 'Kas+Investasi : Utang',
  ratioTotalAssetsToDebt: 'K+I+Aset : Utang',
  ratioDebtToAsset: 'Utang thd Aset',
  noDebt: 'Tidak ada utang',
  budgetThisMonth: 'Anggaran Bulan Ini',
  budgetNotSetYet: 'Belum diatur — atur sekarang',
  recentTransactions: 'Transaksi Terakhir',
  viewAll: 'Lihat semua',
  noTransactionsYet: 'Belum ada transaksi.',
  cancel: 'Batal',
  delete: 'Hapus',
  dialogDeleteTransactionTitle: 'Hapus transaksi ini?',
  deleteTransactionFailed: 'Gagal menghapus transaksi.',
  assetsDebtTooltip: 'Aset & Utang',
  moreMenuTooltip: 'Menu lainnya',
  statIncome: 'Pemasukan',
  statExpense: 'Pengeluaran',
  statBalance: 'Saldo',
  historySectionTitle: 'Riwayat',
  viewInvoiceTooltip: 'Lihat foto invoice',
  payDebtPrefix: 'Bayar utang: ',
  invoiceMaxSizeError: 'Ukuran foto invoice maksimal 10MB.',
  ocrFoundAmount: 'jumlah',
  ocrFoundDate: 'tanggal',
  ocrFoundVendor: 'nama toko',
  ocrFoundPrefix: 'Terbaca: ',
  ocrFoundSuffix: '. Periksa & lengkapi kategori sebelum simpan.',
  ocrNotFound:
      'Tidak ada data yang terbaca jelas dari foto ini. Silakan isi manual.',
  ocrFailed: 'Gagal membaca invoice. Silakan isi manual.',
  categoryFallbackName: 'kategori ini',
  amountInvalid: 'Jumlah tidak valid.',
  transactionNameRequired: 'Nama transaksi wajib diisi.',
  invoiceSavedLocallyFailed:
      'Transaksi tersimpan, tapi foto invoice gagal disimpan lokal (mungkin storage HP penuh).',
  saveTransactionFailed: 'Gagal menyimpan transaksi.',
  editTransactionTitle: 'Ubah Transaksi',
  addTransactionTitle: 'Tambah Transaksi',
  scanInvoiceOptional: 'Scan Invoice (opsional)',
  takePhoto: 'Ambil foto',
  gallery: 'Galeri',
  readingInvoice: 'Membaca invoice…',
  invoiceLocalDisclosure:
      'Foto ini TIDAK PERNAH dikirim ke server — hanya tersimpan terenkripsi '
      'di HP ini. Tidak bisa dilihat dari device lain, dan bisa hilang kalau '
      'aplikasi di-uninstall (kecuali sudah pernah dibackup lewat menu '
      'Backup & Pulihkan).',
  amountFieldLabel: 'Jumlah (Rp)',
  transactionNameFieldLabel:
      'Nama Transaksi (mis. Makan siang di warung Bu As)',
  categoryLabel: 'Kategori',
  manageCategoryLink: 'Kelola kategori →',
  oldCategorySuffix: ' (kategori lama)',
  dateFieldLabel: 'Tanggal',
  cashAccountLabel: 'Akun kas/bank',
  manageAccountLink: 'Kelola akun →',
  linkToDebtLabel: 'Kaitkan ke utang (opsional)',
  notLinked: 'Tidak dikaitkan',
  remainingPrefix: ' — sisa ',
  noteFieldLabel: 'Catatan (opsional)',
  saveChanges: 'Simpan Perubahan',
  addButton: 'Tambah',
  assetsDebtScreenTitle: 'Aset & Utang',
  tabCashAccounts: 'Akun Kas',
  tabDebts: 'Utang',
  totalCash: 'Total Kas',
  sectionCashBank: 'Akun Kas & Bank',
  totalFixedAssets: 'Total Aset Tetap',
  noFixedAssetsYet: 'Belum ada aset tetap.',
  updateValueButton: 'Perbarui nilai',
  totalInvestments: 'Total Investasi',
  noInvestmentsYet: 'Belum ada investasi.',
  totalActiveDebt: 'Total Utang Aktif',
  debtsInstallments: 'Utang & Cicilan',
  manageDebtLink: 'Kelola utang →',
  noActiveDebtYet: 'Tidak ada utang aktif.',
  perMonthSuffix: '/bln',
  deleteAccountFailed:
      'Gagal menghapus akun (mungkin masih dipakai transaksi).',
  deleteAssetFailed: 'Gagal menghapus aset.',
  deleteInvestmentFailed: 'Gagal menghapus investasi.',
  accountNameRequired: 'Nama akun wajib diisi.',
  addAccountFailed: 'Gagal menambah akun.',
  addAccountTitle: 'Tambah Akun',
  accountNameFieldHint: 'Nama akun (mis. BCA, Tunai, GoPay)',
  accountTypeLabel: 'Jenis akun',
  assetNameRequired: 'Nama aset wajib diisi.',
  assetValueInvalid: 'Nilai aset tidak valid.',
  addAssetFailed: 'Gagal menambah aset.',
  addAssetTitle: 'Tambah Aset Tetap',
  assetNameFieldHint: 'Nama aset (mis. Rumah Cluster ABC)',
  assetTypeLabel: 'Jenis aset',
  currentValueEstimateLabel: 'Estimasi nilai saat ini (Rp)',
  valueInvalid: 'Nilai tidak valid.',
  updateValueFailed: 'Gagal memperbarui nilai.',
  currentlyPrefix: 'Saat ini: ',
  newValueEstimateLabel: 'Estimasi nilai baru (Rp)',
  budgetScreenTitle: 'Anggaran Bulanan',
  saveBudgetFailed: 'Gagal menyimpan anggaran.',
  noCategoryYetBudget:
      'Belum ada kategori. Tambah dulu lewat "Kelola kategori".',
  totalRealizationThisMonth: 'Total Realisasi Bulan Ini',
  categoryScreenTitle: 'Kategori Transaksi',
  tabExpenseCategory: 'Kategori Pengeluaran',
  tabIncomeCategory: 'Kategori Pemasukan',
  categoryNameRequired: 'Nama kategori wajib diisi.',
  addCategoryFailed: 'Gagal menambah kategori (mungkin nama sudah dipakai).',
  updateCategoryFailed: 'Gagal mengubah kategori (mungkin nama sudah dipakai).',
  deleteCategoryInUse:
      'Kategori masih dipakai oleh transaksi atau anggaran, tidak bisa dihapus.',
  expenseCategoryDescription:
      'Kategori pengeluaran dipakai untuk memilih kategori transaksi '
      'pengeluaran, dan menjadi daftar kategori Anggaran Bulanan.',
  incomeCategoryDescription:
      'Kategori pemasukan dipakai untuk memilih kategori transaksi pemasukan.',
  newExpenseCategoryHint: 'Nama kategori baru (mis. Donasi)',
  newIncomeCategoryHint: 'Nama kategori baru (mis. Hadiah)',
  noExpenseCategoryYet: 'Belum ada kategori pengeluaran.',
  noIncomeCategoryYet: 'Belum ada kategori pemasukan.',
  editButton: 'Ubah',
  tabFinancialReport: 'Laporan Keuangan',
  tabFinancialHealth: 'Kesehatan Keuangan',
  fromLabel: 'Dari',
  toLabel: 'Sampai',
  typeLabel: 'Tipe',
  filterAll: 'Semua',
  clearCategoryFilter: 'Bersihkan pilihan kategori',
  statBalanceNet: 'Saldo Bersih',
  categoryBreakdownTitle: 'Rincian per Kategori',
  noDataInRange: 'Tidak ada data pada rentang ini.',
  noTransactionInRange: 'Tidak ada transaksi pada rentang ini.',
  debtInstallmentSummaryTitle: 'Ringkasan Utang & Cicilan',
  remainingDebt: 'Sisa Utang',
  installmentPerMonth: 'Cicilan/Bulan',
  financialRatiosCurrentTitle: 'Rasio Keuangan (posisi saat ini)',
  ratioCashInvestDebtFull: 'Kas + Investasi : Utang',
  ratioCashInvestAssetDebtFull: 'Kas + Investasi + Aset Tetap : Utang',
  ratioDebtToAssetFull: 'Rasio Utang terhadap Aset (Debt-to-Asset)',
  debtToAssetExplanation:
      'Rasio Utang terhadap Aset: ≤30% umumnya dianggap sehat, 30–50% '
      'waspada, >50% berisiko tinggi.',
  savingsRatioLabel: 'Rasio Menabung',
  emergencyFundLabel: 'Cakupan Dana Darurat',
  budgetDisciplineLabel: 'Kedisiplinan Anggaran',
  debtToIncomeLabel: 'Rasio Utang terhadap Pemasukan',
  noIncomeDataThisMonth: 'Belum ada data pemasukan bulan ini.',
  notEnoughExpenseData3Months: 'Belum cukup data pengeluaran 3 bulan terakhir.',
  noBudgetSetYet: 'Belum ada anggaran yang diatur.',
  savingsAdviceGood:
      'Bagus, kamu berhasil menyisihkan cukup banyak dari pemasukan bulan ini.',
  savingsAdviceWarn:
      'Lumayan, coba tingkatkan lagi porsi tabungan menuju 20% dari pemasukan.',
  savingsAdviceBad:
      'Pengeluaran bulan ini mendekati atau melebihi pemasukan — coba tekan '
      'pengeluaran non-esensial.',
  emergencyAdviceGood:
      'Dana daruratmu sudah cukup kuat, di atas atau mendekati 6 bulan pengeluaran.',
  emergencyAdviceWarn:
      'Sudah ada bantalan dana darurat, tapi terus tambah menuju 6 bulan pengeluaran.',
  emergencyAdviceBad:
      'Dana darurat masih tipis — prioritaskan menabung sebelum pengeluaran '
      'yang tidak mendesak.',
  disciplineAdviceGood:
      'Sebagian besar anggaran masih terkendali, pertahankan.',
  disciplineAdviceWarn:
      'Beberapa kategori sudah melewati anggaran — cek kategori mana yang '
      'paling boros.',
  disciplineAdviceBad:
      'Banyak kategori melewati anggaran bulan ini, coba tinjau ulang batas '
      'atau kurangi pengeluaran.',
  debtRatioAdviceGood: 'Beban cicilan masih ringan dibanding pemasukan.',
  debtRatioAdviceWarn:
      'Beban cicilan mulai terasa — hati-hati menambah utang baru.',
  debtRatioAdviceBad:
      'Beban cicilan cukup berat dibanding pemasukan, pertimbangkan '
      'percepatan pelunasan atau restrukturisasi.',
  notEnoughDataForScore:
      'Belum cukup data untuk menghitung skor kesehatan keuangan.',
  healthScoreTitle: 'Skor Kesehatan Keuangan',
  healthy: 'Sehat',
  fairlyHealthy: 'Cukup Sehat',
  needsAttention: 'Perlu Perhatian',
  deleteDebtFailed: 'Gagal menghapus utang.',
  totalRemainingDebt: 'Total Sisa Utang',
  noDebtYet: 'Belum ada utang.',
  paidOffSuffix: ' · Lunas',
  recordPaymentButton: 'Catat pembayaran',
  debtNameRequired: 'Nama utang wajib diisi.',
  principalTotalInvalid: 'Total pokok tidak valid.',
  monthlyInstallmentInvalid: 'Cicilan per bulan tidak valid.',
  addDebtFailed: 'Gagal menambah utang.',
  addDebtTitle: 'Tambah Utang',
  debtNameFieldHint: 'Nama utang (mis. KPR Rumah)',
  debtTypeLabel: 'Jenis utang',
  principalTotalLabel: 'Total pokok utang (Rp)',
  monthlyInstallmentLabel: 'Cicilan per bulan (Rp)',
  startDateLabel: 'Tanggal mulai',
  paymentAmountInvalid: 'Jumlah pembayaran tidak valid.',
  recordPaymentFailed: 'Gagal mencatat pembayaran.',
  currentRemainingPrefix: 'Sisa saat ini: ',
  paymentAmountLabel: 'Jumlah pembayaran (Rp)',
  payButton: 'Bayar',
  unknownLabel: 'tidak diketahui',
  confirmRestoreTitle: 'Pulihkan backup ini?',
  restoreButton: 'Pulihkan',
  creatingBackup: 'Membuat backup...',
  backupCreatedSuccess: 'Backup berhasil dibuat.',
  readingBackupFile: 'Membaca file backup...',
  restoringData: 'Memulihkan data...',
  restoreSuccess:
      'Data berhasil dipulihkan. Buka ulang Beranda untuk melihatnya.',
  processingLabel: 'Memproses...',
  createBackupTitle: 'Buat Backup',
  createBackupDescription:
      'Salinan data keuangan rumah tangga (dan, kalau dipilih, foto invoice '
      'lokal juga), dienkripsi dengan passphrase yang Anda buat sendiri. '
      'Dari kotak dialog berbagi, Anda bisa langsung kirim ke Google Drive, '
      'email sendiri, atau aplikasi penyimpanan lain.',
  createSaveBackupTitle: 'Buat & Simpan Backup',
  createSaveBackupSubtitle:
      'Simpan ke HP, atau kirim ke Google Drive/aplikasi lain',
  restoreFromBackupTitle: 'Pulihkan dari Backup',
  restoreDescription:
      'Mengganti total seluruh data rumah tangga saat ini dengan isi backup '
      '(termasuk lampiran, kalau backup-nya menyertakannya).',
  chooseBackupFileTitle: 'Pilih File Backup',
  chooseBackupFileSubtitle:
      'Pilih file backup yang tersimpan di HP (termasuk yang diunduh dari '
      'Google Drive)',
  passphraseMinLength: 'Passphrase minimal 8 karakter.',
  passphraseMismatch: 'Konfirmasi passphrase tidak cocok.',
  createPassphraseTitle: 'Buat Passphrase Backup',
  passphraseWarning:
      'Ingat baik-baik passphrase ini. Kalau lupa, backup ini TIDAK BISA '
      'dipulihkan lagi oleh siapa pun — termasuk kami. Passphrase tidak '
      'pernah dikirim atau disimpan di server.',
  passphraseLabel: 'Passphrase',
  repeatPassphraseLabel: 'Ulangi passphrase',
  includeAttachmentsTitle: 'Sertakan lampiran (foto invoice lokal)',
  includeAttachmentsSubtitleOn:
      'Backup akan berisi data + foto invoice — filenya jadi lebih besar.',
  includeAttachmentsSubtitleOff:
      'Backup cuma berisi data keuangan saja (transaksi, akun, dst), tanpa foto.',
  continueButton: 'Lanjutkan',
  enterPassphraseTitle: 'Masukkan Passphrase Backup',
  quickGuideTitle: '👋 Panduan Singkat',
  quickGuideSubtitle:
      'Tap salah satu fitur di bawah untuk lihat cara pakainya.',
  viewIntroTutorialAgain: 'Lihat tutorial perkenalan lagi',
  privacyPolicyLink: 'Kebijakan Privasi',
  termsLink: 'Syarat & Ketentuan',
  deleteAccountLink: 'Hapus Akun',
  helpDarkModeTitle: 'Mode Gelap & Terang',
  helpTxPoint1:
      'Tap tombol "+" di pojok kanan bawah Beranda untuk catat transaksi baru, kapan saja.',
  helpTxPoint2:
      'Pilih jenisnya: Pemasukan atau Pengeluaran, lalu isi jumlah, nama, kategori, dan akun (kas/bank).',
  helpTxPoint3:
      'Bisa langsung foto struk belanja — jumlah, tanggal, dan nama toko akan '
      'otomatis terisi lewat pemindaian di HP (tidak dikirim ke internet).',
  helpTxPoint4:
      'Tap transaksi mana pun di daftar untuk melihat detail atau mengubahnya.',
  helpAssetPoint1:
      'Halaman ini punya 4 tab: Akun Kas, Aset Tetap, Investasi, dan Utang — '
      'geser atau tap judul tab untuk pindah.',
  helpAssetPoint2:
      'Tap card Kas / Aset Tetap / Investasi / Utang Aktif di Beranda untuk '
      'langsung lompat ke tab yang sesuai.',
  helpAssetPoint3:
      'Tambah akun baru (BCA, Tunai, GoPay, dst), aset tetap (rumah, '
      'kendaraan), atau investasi lewat tombol "Tambah" di tiap tab.',
  helpAssetPoint4:
      'Untuk mengelola cicilan utang secara detail, tap "Kelola utang →" di '
      'tab Utang.',
  helpBudgetPoint1:
      'Atur batas pengeluaran bulanan untuk tiap kategori (mis. Makanan Rp '
      '2.000.000/bulan).',
  helpBudgetPoint2:
      'Setelah diisi, halaman ini otomatis menampilkan progress realisasi: '
      'berapa yang sudah terpakai dari batas tersebut, dengan warna '
      'hijau/kuning/merah.',
  helpBudgetPoint3:
      'Kalau pengeluaran di suatu kategori sudah melewati anggarannya, akan '
      'muncul peringatan singkat saat mencatat transaksi.',
  helpBudgetPoint4:
      'Card "Anggaran Bulan Ini" di Beranda menampilkan ringkasannya — tap '
      'untuk buka halaman lengkap.',
  helpReportPoint1:
      'Tab "Laporan Keuangan" menampilkan ringkasan pemasukan/pengeluaran dan '
      'grafik per kategori.',
  helpReportPoint2:
      'Tab "Kesehatan Keuangan" memberi skor 0–100 berdasarkan 4 indikator: '
      'rasio tabungan, dana darurat, kedisiplinan anggaran, dan rasio utang.',
  helpReportPoint3:
      'Tiap indikator ada saran singkat kalau skornya masih rendah — jadikan '
      'panduan untuk perbaikan bulan depan.',
  helpDarkModePoint1:
      'Tap ikon matahari/bulan di pojok kanan atas Beranda untuk beralih mode '
      'gelap/terang kapan saja.',
  helpDarkModePoint2:
      'Perubahan langsung berlaku ke seluruh aplikasi, tidak perlu buka-tutup '
      'ulang.',
  areYouSureTitle: 'Yakin?',
  deleteAccountConfirmBody:
      'Semua data keuangan rumah tangga ini akan terhapus permanen dan tidak '
      'bisa dikembalikan.',
  deleteAccountFailedGeneric: 'Gagal menghapus akun. Coba lagi nanti.',
  dangerZoneTitle: 'Zona Berbahaya',
  dangerZoneDescription:
      'Menghapus akun akan menghapus secara permanen akun Anda beserta '
      'seluruh data rumah tangga (transaksi, akun kas/bank, aset, utang, '
      'investasi, dan anggaran). Tindakan ini tidak bisa dibatalkan. Jika '
      'rumah tangga Anda memiliki anggota lain, hubungi '
      'privacy@dompetdigitalku.my.id terlebih dahulu.',
  deleteConfirmWord: 'HAPUS',
  deleteAccountAndAllDataButton: 'Hapus Akun & Semua Data',
  signInToContinue: 'Masuk untuk lanjutkan',
  emailLabel: 'Email',
  passwordLabel: 'Password',
  genericConnectionError: 'Terjadi kesalahan. Periksa koneksi internet Anda.',
  signInButton: 'Masuk',
  orDivider: 'atau',
  signInWithGoogle: 'Masuk dengan Google',
  googleConsentPrefix: 'Dengan masuk/mendaftar lewat Google, Anda menyetujui ',
  googleConsentMiddle: ' dan ',
  googleConsentSuffix: ' kami.',
  noAccountYetPrefix: 'Belum punya akun? ',
  registerTitle: 'Daftar',
  registerSubtitle: 'Buat akun & rumah tangga baru',
  yourNameLabel: 'Nama Anda',
  householdNameLabel: 'Nama Keluarga',
  householdNameHint: 'mis. Keluarga Budi',
  agreeConsentPrefix: 'Saya menyetujui ',
  agreeConsentSuffix: ' DompetDigitalKu.',
  mustAgreeError:
      'Anda harus menyetujui Kebijakan Privasi & Syarat Ketentuan untuk mendaftar.',
  registerButton: 'Daftar',
  registerSuccessMessage: 'Registrasi berhasil! Mengarahkan ke halaman masuk...',
  registerFailedGeneric: 'Gagal mendaftar. Periksa koneksi internet Anda.',
  alreadyHaveAccountPrefix: 'Sudah punya akun? ',
  transactionDetailTitle: 'Detail Transaksi',
  transactionNameLabel: 'Nama Transaksi',
  debtLinkLabel: 'Kaitan utang',
  noteLabel: 'Catatan',
  invoicePhotoLabel: 'Foto Invoice',
  failedLoadPhoto: 'Gagal memuat foto.',
  failedLoadInvoicePhoto: 'Gagal memuat foto invoice.',
  investmentNameRequired: 'Nama investasi wajib diisi.',
  initialCapitalInvalid: 'Modal awal tidak valid.',
  addInvestmentFailed: 'Gagal menambah investasi.',
  addInvestmentTitle: 'Tambah Investasi',
  investmentNameLabel: 'Nama investasi',
  investmentTypeLabel: 'Jenis investasi',
  initialCapitalLabel: 'Modal awal (Rp)',
  currentValueEmptyLabel: 'Nilai saat ini (kosongkan = sama dengan modal)',
  currentValueLabel: 'Nilai saat ini (Rp)',
  onboardWelcomeTitle: 'Selamat Datang di\nDompetDigitalKu 👋',
  onboardWelcomeDesc:
      'Kelola keuangan keluarga jadi lebih mudah, rapi, dan transparan — '
      'semua di satu tempat.',
  onboardTxTitle: 'Catat Transaksi Sekejap',
  onboardTxDesc:
      'Tap tombol "+" di Beranda untuk catat pemasukan/pengeluaran. Bisa '
      'juga foto struk — jumlah & tanggal otomatis terisi.',
  onboardAssetsDesc:
      'Pantau saldo kas, aset tetap, investasi, dan utang dalam satu halaman '
      'bertab. Tap card di Beranda untuk lompat langsung.',
  onboardBudgetTitle: 'Anggaran & Realisasi',
  onboardBudgetDesc:
      'Atur batas pengeluaran per kategori, lalu pantau progress '
      'pemakaiannya secara langsung — lengkap dengan peringatan kalau '
      'kelebihan.',
  onboardHealthTitle: 'Kesehatan Keuangan',
  onboardHealthDesc:
      'Dapatkan skor kesehatan keuangan keluarga beserta saran '
      'perbaikannya, di tab Laporan.',
  skipButton: 'Lewati',
  startNowButton: 'Mulai Sekarang',
  nextButton: 'Lanjut',
);

const _en = AppStringsData(
  appName: 'DompetDigitalKu',
  languageSwitchTooltip: 'Language',
  languageIndonesian: 'Indonesian',
  languageEnglish: 'English',
  home: 'Home',
  errorLoadData: 'Failed to load data. Pull down to try again.',
  noCashAccountYet: 'No cash/bank account yet.',
  noCategoryYet: 'No category yet. Add one first via the Category menu.',
  addTransactionTooltip: 'Add transaction',
  lightMode: 'Light mode',
  darkMode: 'Dark mode',
  backupRestoreTooltip: 'Backup & Restore',
  helpTooltip: 'Help & Guide',
  logoutTooltip: 'Log out',
  menuTransactions: 'Transactions',
  menuAssets: 'Assets, Investments & Debts',
  menuBudget: 'Budget',
  menuReportsFull: 'Reports & Financial Health',
  menuReportsShort: 'Reports',
  totalNetAssets: 'Total Net Assets',
  statCash: 'Cash',
  statFixedAssets: 'Fixed Assets',
  statInvestments: 'Investments',
  statActiveDebt: 'Active Debt',
  financialRatios: 'Financial Ratios',
  ratioCashInvestToDebt: 'Cash+Invest : Debt',
  ratioTotalAssetsToDebt: 'C+I+Asset : Debt',
  ratioDebtToAsset: 'Debt to Asset',
  noDebt: 'No debt',
  budgetThisMonth: "This Month's Budget",
  budgetNotSetYet: 'Not set yet — set it now',
  recentTransactions: 'Recent Transactions',
  viewAll: 'View all',
  noTransactionsYet: 'No transactions yet.',
  cancel: 'Cancel',
  delete: 'Delete',
  dialogDeleteTransactionTitle: 'Delete this transaction?',
  deleteTransactionFailed: 'Failed to delete transaction.',
  assetsDebtTooltip: 'Assets & Debts',
  moreMenuTooltip: 'More menu',
  statIncome: 'Income',
  statExpense: 'Expense',
  statBalance: 'Balance',
  historySectionTitle: 'History',
  viewInvoiceTooltip: 'View invoice photo',
  payDebtPrefix: 'Pay debt: ',
  invoiceMaxSizeError: 'Invoice photo size is max 10MB.',
  ocrFoundAmount: 'amount',
  ocrFoundDate: 'date',
  ocrFoundVendor: 'store name',
  ocrFoundPrefix: 'Detected: ',
  ocrFoundSuffix: '. Check & complete the category before saving.',
  ocrNotFound:
      'No data was clearly read from this photo. Please fill in manually.',
  ocrFailed: 'Failed to read invoice. Please fill in manually.',
  categoryFallbackName: 'this category',
  amountInvalid: 'Invalid amount.',
  transactionNameRequired: 'Transaction name is required.',
  invoiceSavedLocallyFailed:
      'Transaction saved, but the invoice photo failed to save locally '
      '(device storage may be full).',
  saveTransactionFailed: 'Failed to save transaction.',
  editTransactionTitle: 'Edit Transaction',
  addTransactionTitle: 'Add Transaction',
  scanInvoiceOptional: 'Scan Invoice (optional)',
  takePhoto: 'Take photo',
  gallery: 'Gallery',
  readingInvoice: 'Reading invoice…',
  invoiceLocalDisclosure:
      'This photo is NEVER sent to the server — it is only stored '
      'encrypted on this device. It cannot be viewed from another device, '
      'and may be lost if the app is uninstalled (unless it was already '
      'backed up via the Backup & Restore menu).',
  amountFieldLabel: 'Amount (Rp)',
  transactionNameFieldLabel: "Transaction Name (e.g. Lunch at Bu As's stall)",
  categoryLabel: 'Category',
  manageCategoryLink: 'Manage categories →',
  oldCategorySuffix: ' (old category)',
  dateFieldLabel: 'Date',
  cashAccountLabel: 'Cash/bank account',
  manageAccountLink: 'Manage accounts →',
  linkToDebtLabel: 'Link to debt (optional)',
  notLinked: 'Not linked',
  remainingPrefix: ' — remaining ',
  noteFieldLabel: 'Note (optional)',
  saveChanges: 'Save Changes',
  addButton: 'Add',
  assetsDebtScreenTitle: 'Assets & Debts',
  tabCashAccounts: 'Cash Accounts',
  tabDebts: 'Debts',
  totalCash: 'Total Cash',
  sectionCashBank: 'Cash & Bank Accounts',
  totalFixedAssets: 'Total Fixed Assets',
  noFixedAssetsYet: 'No fixed assets yet.',
  updateValueButton: 'Update value',
  totalInvestments: 'Total Investments',
  noInvestmentsYet: 'No investments yet.',
  totalActiveDebt: 'Total Active Debt',
  debtsInstallments: 'Debts & Installments',
  manageDebtLink: 'Manage debts →',
  noActiveDebtYet: 'No active debt.',
  perMonthSuffix: '/mo',
  deleteAccountFailed:
      'Failed to delete account (it may still be used by a transaction).',
  deleteAssetFailed: 'Failed to delete asset.',
  deleteInvestmentFailed: 'Failed to delete investment.',
  accountNameRequired: 'Account name is required.',
  addAccountFailed: 'Failed to add account.',
  addAccountTitle: 'Add Account',
  accountNameFieldHint: 'Account name (e.g. BCA, Cash, GoPay)',
  accountTypeLabel: 'Account type',
  assetNameRequired: 'Asset name is required.',
  assetValueInvalid: 'Invalid asset value.',
  addAssetFailed: 'Failed to add asset.',
  addAssetTitle: 'Add Fixed Asset',
  assetNameFieldHint: 'Asset name (e.g. Cluster ABC House)',
  assetTypeLabel: 'Asset type',
  currentValueEstimateLabel: 'Current estimated value (Rp)',
  valueInvalid: 'Invalid value.',
  updateValueFailed: 'Failed to update value.',
  currentlyPrefix: 'Currently: ',
  newValueEstimateLabel: 'New estimated value (Rp)',
  budgetScreenTitle: 'Monthly Budget',
  saveBudgetFailed: 'Failed to save budget.',
  noCategoryYetBudget:
      'No category yet. Add one first via "Manage categories".',
  totalRealizationThisMonth: 'Total Realization This Month',
  categoryScreenTitle: 'Transaction Categories',
  tabExpenseCategory: 'Expense Categories',
  tabIncomeCategory: 'Income Categories',
  categoryNameRequired: 'Category name is required.',
  addCategoryFailed: 'Failed to add category (name may already be in use).',
  updateCategoryFailed:
      'Failed to update category (name may already be in use).',
  deleteCategoryInUse:
      'Category is still used by a transaction or budget, cannot be deleted.',
  expenseCategoryDescription:
      'Expense categories are used to pick a category for expense '
      'transactions, and become the category list for the Monthly Budget.',
  incomeCategoryDescription:
      'Income categories are used to pick a category for income transactions.',
  newExpenseCategoryHint: 'New category name (e.g. Donation)',
  newIncomeCategoryHint: 'New category name (e.g. Gift)',
  noExpenseCategoryYet: 'No expense category yet.',
  noIncomeCategoryYet: 'No income category yet.',
  editButton: 'Edit',
  tabFinancialReport: 'Financial Report',
  tabFinancialHealth: 'Financial Health',
  fromLabel: 'From',
  toLabel: 'To',
  typeLabel: 'Type',
  filterAll: 'All',
  clearCategoryFilter: 'Clear category selection',
  statBalanceNet: 'Net Balance',
  categoryBreakdownTitle: 'Breakdown by Category',
  noDataInRange: 'No data in this range.',
  noTransactionInRange: 'No transactions in this range.',
  debtInstallmentSummaryTitle: 'Debt & Installment Summary',
  remainingDebt: 'Remaining Debt',
  installmentPerMonth: 'Installment/Month',
  financialRatiosCurrentTitle: 'Financial Ratios (current position)',
  ratioCashInvestDebtFull: 'Cash + Investments : Debt',
  ratioCashInvestAssetDebtFull: 'Cash + Investments + Fixed Assets : Debt',
  ratioDebtToAssetFull: 'Debt-to-Asset Ratio',
  debtToAssetExplanation:
      'Debt-to-Asset Ratio: ≤30% is generally considered healthy, 30–50% '
      'caution, >50% high risk.',
  savingsRatioLabel: 'Savings Ratio',
  emergencyFundLabel: 'Emergency Fund Coverage',
  budgetDisciplineLabel: 'Budget Discipline',
  debtToIncomeLabel: 'Debt-to-Income Ratio',
  noIncomeDataThisMonth: 'No income data for this month yet.',
  notEnoughExpenseData3Months: 'Not enough expense data for the last 3 months.',
  noBudgetSetYet: 'No budget set yet.',
  savingsAdviceGood:
      "Great, you managed to set aside a good portion of this month's income.",
  savingsAdviceWarn:
      'Decent, try to increase your savings portion toward 20% of income.',
  savingsAdviceBad:
      "This month's expenses are near or above income — try to cut "
      'non-essential spending.',
  emergencyAdviceGood:
      'Your emergency fund is solid, at or near 6 months of expenses.',
  emergencyAdviceWarn:
      'You have some emergency fund cushion, but keep building toward 6 '
      'months of expenses.',
  emergencyAdviceBad:
      'Your emergency fund is still thin — prioritize saving before '
      'non-urgent spending.',
  disciplineAdviceGood:
      'Most of your budget is still under control, keep it up.',
  disciplineAdviceWarn:
      'Some categories have already exceeded their budget — check which '
      'ones are overspending the most.',
  disciplineAdviceBad:
      'Many categories exceeded their budget this month, consider revising '
      'the limits or cutting spending.',
  debtRatioAdviceGood:
      'Your installment burden is still light compared to income.',
  debtRatioAdviceWarn:
      'Your installment burden is starting to add up — be cautious about '
      'taking on new debt.',
  debtRatioAdviceBad:
      'Your installment burden is fairly heavy compared to income, consider '
      'accelerating repayment or restructuring.',
  notEnoughDataForScore:
      'Not enough data to calculate the financial health score.',
  healthScoreTitle: 'Financial Health Score',
  healthy: 'Healthy',
  fairlyHealthy: 'Fairly Healthy',
  needsAttention: 'Needs Attention',
  deleteDebtFailed: 'Failed to delete debt.',
  totalRemainingDebt: 'Total Remaining Debt',
  noDebtYet: 'No debt yet.',
  paidOffSuffix: ' · Paid Off',
  recordPaymentButton: 'Record payment',
  debtNameRequired: 'Debt name is required.',
  principalTotalInvalid: 'Invalid principal total.',
  monthlyInstallmentInvalid: 'Invalid monthly installment.',
  addDebtFailed: 'Failed to add debt.',
  addDebtTitle: 'Add Debt',
  debtNameFieldHint: 'Debt name (e.g. Home Mortgage)',
  debtTypeLabel: 'Debt type',
  principalTotalLabel: 'Total principal (Rp)',
  monthlyInstallmentLabel: 'Monthly installment (Rp)',
  startDateLabel: 'Start date',
  paymentAmountInvalid: 'Invalid payment amount.',
  recordPaymentFailed: 'Failed to record payment.',
  currentRemainingPrefix: 'Current remaining: ',
  paymentAmountLabel: 'Payment amount (Rp)',
  payButton: 'Pay',
  unknownLabel: 'unknown',
  confirmRestoreTitle: 'Restore this backup?',
  restoreButton: 'Restore',
  creatingBackup: 'Creating backup...',
  backupCreatedSuccess: 'Backup created successfully.',
  readingBackupFile: 'Reading backup file...',
  restoringData: 'Restoring data...',
  restoreSuccess: 'Data restored successfully. Reopen Home to see it.',
  processingLabel: 'Processing...',
  createBackupTitle: 'Create Backup',
  createBackupDescription:
      "A copy of your household's financial data (and, if selected, local "
      'invoice photos too), encrypted with a passphrase you create yourself. '
      'From the share sheet, you can send it directly to Google Drive, your '
      'own email, or another storage app.',
  createSaveBackupTitle: 'Create & Save Backup',
  createSaveBackupSubtitle:
      'Save to device, or send to Google Drive/other apps',
  restoreFromBackupTitle: 'Restore from Backup',
  restoreDescription:
      "Replaces ALL of your household's current data with the backup's "
      'contents (including attachments, if the backup includes them).',
  chooseBackupFileTitle: 'Choose Backup File',
  chooseBackupFileSubtitle:
      'Choose a backup file stored on this device (including ones '
      'downloaded from Google Drive)',
  passphraseMinLength: 'Passphrase must be at least 8 characters.',
  passphraseMismatch: 'Passphrase confirmation does not match.',
  createPassphraseTitle: 'Create Backup Passphrase',
  passphraseWarning:
      'Remember this passphrase carefully. If you forget it, this backup '
      'CANNOT be restored by anyone — including us. The passphrase is never '
      'sent to or stored on the server.',
  passphraseLabel: 'Passphrase',
  repeatPassphraseLabel: 'Repeat passphrase',
  includeAttachmentsTitle: 'Include attachments (local invoice photos)',
  includeAttachmentsSubtitleOn:
      'The backup will include data + invoice photos — the file will be larger.',
  includeAttachmentsSubtitleOff:
      'The backup will only contain financial data (transactions, accounts, '
      'etc.), no photos.',
  continueButton: 'Continue',
  enterPassphraseTitle: 'Enter Backup Passphrase',
  quickGuideTitle: '👋 Quick Guide',
  quickGuideSubtitle: 'Tap one of the features below to see how to use it.',
  viewIntroTutorialAgain: 'View intro tutorial again',
  privacyPolicyLink: 'Privacy Policy',
  termsLink: 'Terms & Conditions',
  deleteAccountLink: 'Delete Account',
  helpDarkModeTitle: 'Dark & Light Mode',
  helpTxPoint1:
      'Tap the "+" button at the bottom-right of Home to record a new '
      'transaction any time.',
  helpTxPoint2:
      'Choose the type: Income or Expense, then fill in the amount, name, '
      'category, and account (cash/bank).',
  helpTxPoint3:
      "You can photograph a receipt directly — the amount, date, and store "
      "name will be filled in automatically via on-device scanning (never "
      "sent over the internet).",
  helpTxPoint4:
      'Tap any transaction in the list to view its details or edit it.',
  helpAssetPoint1:
      'This page has 4 tabs: Cash Accounts, Fixed Assets, Investments, and '
      'Debts — swipe or tap a tab title to switch.',
  helpAssetPoint2:
      'Tap the Cash / Fixed Assets / Investments / Active Debt card on Home '
      'to jump straight to the matching tab.',
  helpAssetPoint3:
      'Add a new account (BCA, Cash, GoPay, etc.), fixed asset (house, '
      'vehicle), or investment via the "Add" button on each tab.',
  helpAssetPoint4:
      'To manage debt installments in detail, tap "Manage debts →" on the '
      'Debts tab.',
  helpBudgetPoint1:
      'Set a monthly spending limit for each category (e.g. Food Rp '
      '2,000,000/month).',
  helpBudgetPoint2:
      'Once set, this page automatically shows realization progress: how '
      'much of that limit has been used, color-coded green/yellow/red.',
  helpBudgetPoint3:
      "If a category's spending has exceeded its budget, a short warning "
      "appears when recording a transaction.",
  helpBudgetPoint4:
      'The "This Month\'s Budget" card on Home shows a summary — tap it to '
      'open the full page.',
  helpReportPoint1:
      'The "Financial Report" tab shows an income/expense summary and a '
      'per-category breakdown.',
  helpReportPoint2:
      'The "Financial Health" tab gives a 0–100 score based on 4 indicators: '
      'savings ratio, emergency fund, budget discipline, and debt ratio.',
  helpReportPoint3:
      'Each indicator has a short tip when its score is still low — use it '
      'as a guide for next month.',
  helpDarkModePoint1:
      'Tap the sun/moon icon at the top-right of Home to switch dark/light '
      'mode any time.',
  helpDarkModePoint2:
      'The change applies to the whole app instantly, no need to close and '
      'reopen it.',
  areYouSureTitle: 'Are you sure?',
  deleteAccountConfirmBody:
      "All of this household's financial data will be permanently deleted "
      'and cannot be recovered.',
  deleteAccountFailedGeneric: 'Failed to delete account. Try again later.',
  dangerZoneTitle: 'Danger Zone',
  dangerZoneDescription:
      'Deleting your account will permanently remove your account along '
      'with all household data (transactions, cash/bank accounts, assets, '
      'debts, investments, and budgets). This action cannot be undone. If '
      'your household has other members, contact '
      'privacy@dompetdigitalku.my.id first.',
  deleteConfirmWord: 'DELETE',
  deleteAccountAndAllDataButton: 'Delete Account & All Data',
  signInToContinue: 'Sign in to continue',
  emailLabel: 'Email',
  passwordLabel: 'Password',
  genericConnectionError:
      'Something went wrong. Please check your internet connection.',
  signInButton: 'Sign In',
  orDivider: 'or',
  signInWithGoogle: 'Sign in with Google',
  googleConsentPrefix:
      'By signing in/registering with Google, you agree to our ',
  googleConsentMiddle: ' and ',
  googleConsentSuffix: '.',
  noAccountYetPrefix: "Don't have an account yet? ",
  registerTitle: 'Register',
  registerSubtitle: 'Create a new account & household',
  yourNameLabel: 'Your name',
  householdNameLabel: 'Household name',
  householdNameHint: 'e.g. The Smith Family',
  agreeConsentPrefix: 'I agree to the ',
  agreeConsentSuffix: ' of DompetDigitalKu.',
  mustAgreeError:
      'You must agree to the Privacy Policy & Terms of Service to register.',
  registerButton: 'Register',
  registerSuccessMessage: 'Registration successful! Redirecting to sign in...',
  registerFailedGeneric: 'Failed to register. Check your internet connection.',
  alreadyHaveAccountPrefix: 'Already have an account? ',
  transactionDetailTitle: 'Transaction Detail',
  transactionNameLabel: 'Transaction Name',
  debtLinkLabel: 'Debt Link',
  noteLabel: 'Note',
  invoicePhotoLabel: 'Invoice Photo',
  failedLoadPhoto: 'Failed to load photo.',
  failedLoadInvoicePhoto: 'Failed to load invoice photo.',
  investmentNameRequired: 'Investment name is required.',
  initialCapitalInvalid: 'Invalid initial capital.',
  addInvestmentFailed: 'Failed to add investment.',
  addInvestmentTitle: 'Add Investment',
  investmentNameLabel: 'Investment name',
  investmentTypeLabel: 'Investment type',
  initialCapitalLabel: 'Initial capital (Rp)',
  currentValueEmptyLabel: 'Current value (leave empty = same as capital)',
  currentValueLabel: 'Current value (Rp)',
  onboardWelcomeTitle: 'Welcome to\nDompetDigitalKu 👋',
  onboardWelcomeDesc:
      'Manage your family finances more easily, neatly, and transparently — '
      'all in one place.',
  onboardTxTitle: 'Record Transactions Instantly',
  onboardTxDesc:
      'Tap the "+" button on Home to record income/expenses. You can also '
      'photograph a receipt — the amount & date fill in automatically.',
  onboardAssetsDesc:
      'Track your cash balance, fixed assets, investments, and debt in one '
      'tabbed page. Tap a card on Home to jump straight there.',
  onboardBudgetTitle: 'Budget & Realization',
  onboardBudgetDesc:
      "Set a spending limit per category, then track its usage progress "
      "live — complete with a warning if you go over.",
  onboardHealthTitle: 'Financial Health',
  onboardHealthDesc:
      "Get your family's financial health score along with improvement "
      'tips, on the Reports tab.',
  skipButton: 'Skip',
  startNowButton: 'Get Started',
  nextButton: 'Next',
);
