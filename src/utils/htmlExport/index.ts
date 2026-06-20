/**
 * htmlExport/index.ts
 *
 * Public entry point for the HTML export module.
 * Only function exported: formatExportAsHtml(doc).
 * Everything else is handled by the sub-modules.
 */

import type { ExportDocument } from "../../types/export"
import { renderHtmlShell } from "./layout"

export function formatExportAsHtml(doc: ExportDocument): string {
  return renderHtmlShell(doc)
}
