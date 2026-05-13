/// All `document-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin DocumentServiceApi {
  final String documents = 'document-service/documents';
  final String documentsStatus = 'document-service/documents/status';
  final String initDocumentServiceUpload = "document-service/s3/presigned-url";
}
