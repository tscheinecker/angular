var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { SourceModule, SourceExpression, moduleRef } from './source_module';
import { ViewEncapsulation } from 'angular2/src/core/metadata/view';
import { XHR } from 'angular2/src/compiler/xhr';
import { IS_DART, isBlank } from 'angular2/src/facade/lang';
import { PromiseWrapper } from 'angular2/src/facade/async';
import { ShadowCss } from 'angular2/src/compiler/shadow_css';
import { UrlResolver } from 'angular2/src/compiler/url_resolver';
import { extractStyleUrls } from './style_url_resolver';
import { escapeSingleQuoteString, codeGenExportVariable, MODULE_SUFFIX } from './util';
import { Injectable } from 'angular2/src/core/di';
const COMPONENT_VARIABLE = '%COMP%';
const HOST_ATTR = `_nghost-${COMPONENT_VARIABLE}`;
const CONTENT_ATTR = `_ngcontent-${COMPONENT_VARIABLE}`;
export let StyleCompiler = class {
    constructor(_xhr, _urlResolver) {
        this._xhr = _xhr;
        this._urlResolver = _urlResolver;
        this._styleCache = new Map();
        this._shadowCss = new ShadowCss();
    }
    compileComponentRuntime(template) {
        var styles = template.styles;
        var styleAbsUrls = template.styleUrls;
        return this._loadStyles(styles, styleAbsUrls, template.encapsulation === ViewEncapsulation.Emulated);
    }
    compileComponentCodeGen(template) {
        var shim = template.encapsulation === ViewEncapsulation.Emulated;
        return this._styleCodeGen(template.styles, template.styleUrls, shim);
    }
    compileStylesheetCodeGen(stylesheetUrl, cssText) {
        var styleWithImports = extractStyleUrls(this._urlResolver, stylesheetUrl, cssText);
        return [
            this._styleModule(stylesheetUrl, false, this._styleCodeGen([styleWithImports.style], styleWithImports.styleUrls, false)),
            this._styleModule(stylesheetUrl, true, this._styleCodeGen([styleWithImports.style], styleWithImports.styleUrls, true))
        ];
    }
    clearCache() { this._styleCache.clear(); }
    _loadStyles(plainStyles, absUrls, encapsulate) {
        var promises = absUrls.map((absUrl) => {
            var cacheKey = `${absUrl}${encapsulate ? '.shim' : ''}`;
            var result = this._styleCache.get(cacheKey);
            if (isBlank(result)) {
                result = this._xhr.get(absUrl).then((style) => {
                    var styleWithImports = extractStyleUrls(this._urlResolver, absUrl, style);
                    return this._loadStyles([styleWithImports.style], styleWithImports.styleUrls, encapsulate);
                });
                this._styleCache.set(cacheKey, result);
            }
            return result;
        });
        return PromiseWrapper.all(promises).then((nestedStyles) => {
            var result = plainStyles.map(plainStyle => this._shimIfNeeded(plainStyle, encapsulate));
            nestedStyles.forEach(styles => result.push(styles));
            return result;
        });
    }
    _styleCodeGen(plainStyles, absUrls, shim) {
        var arrayPrefix = IS_DART ? `const` : '';
        var styleExpressions = plainStyles.map(plainStyle => escapeSingleQuoteString(this._shimIfNeeded(plainStyle, shim)));
        for (var i = 0; i < absUrls.length; i++) {
            var moduleUrl = this._createModuleUrl(absUrls[i], shim);
            styleExpressions.push(`${moduleRef(moduleUrl)}STYLES`);
        }
        var expressionSource = `${arrayPrefix} [${styleExpressions.join(',')}]`;
        return new SourceExpression([], expressionSource);
    }
    _styleModule(stylesheetUrl, shim, expression) {
        var moduleSource = `
      ${expression.declarations.join('\n')}
      ${codeGenExportVariable('STYLES')}${expression.expression};
    `;
        return new SourceModule(this._createModuleUrl(stylesheetUrl, shim), moduleSource);
    }
    _shimIfNeeded(style, shim) {
        return shim ? this._shadowCss.shimCssText(style, CONTENT_ATTR, HOST_ATTR) : style;
    }
    _createModuleUrl(stylesheetUrl, shim) {
        return shim ? `${stylesheetUrl}.shim${MODULE_SUFFIX}` : `${stylesheetUrl}${MODULE_SUFFIX}`;
    }
};
StyleCompiler = __decorate([
    Injectable(), 
    __metadata('design:paramtypes', [XHR, UrlResolver])
], StyleCompiler);
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoic3R5bGVfY29tcGlsZXIuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyJkaWZmaW5nX3BsdWdpbl93cmFwcGVyLW91dHB1dF9wYXRoLXczRFJsWEppLnRtcC9hbmd1bGFyMi9zcmMvY29tcGlsZXIvc3R5bGVfY29tcGlsZXIudHMiXSwibmFtZXMiOlsiU3R5bGVDb21waWxlciIsIlN0eWxlQ29tcGlsZXIuY29uc3RydWN0b3IiLCJTdHlsZUNvbXBpbGVyLmNvbXBpbGVDb21wb25lbnRSdW50aW1lIiwiU3R5bGVDb21waWxlci5jb21waWxlQ29tcG9uZW50Q29kZUdlbiIsIlN0eWxlQ29tcGlsZXIuY29tcGlsZVN0eWxlc2hlZXRDb2RlR2VuIiwiU3R5bGVDb21waWxlci5jbGVhckNhY2hlIiwiU3R5bGVDb21waWxlci5fbG9hZFN0eWxlcyIsIlN0eWxlQ29tcGlsZXIuX3N0eWxlQ29kZUdlbiIsIlN0eWxlQ29tcGlsZXIuX3N0eWxlTW9kdWxlIiwiU3R5bGVDb21waWxlci5fc2hpbUlmTmVlZGVkIiwiU3R5bGVDb21waWxlci5fY3JlYXRlTW9kdWxlVXJsIl0sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7T0FDTyxFQUFDLFlBQVksRUFBRSxnQkFBZ0IsRUFBRSxTQUFTLEVBQUMsTUFBTSxpQkFBaUI7T0FDbEUsRUFBQyxpQkFBaUIsRUFBQyxNQUFNLGlDQUFpQztPQUMxRCxFQUFDLEdBQUcsRUFBQyxNQUFNLDJCQUEyQjtPQUN0QyxFQUFDLE9BQU8sRUFBaUIsT0FBTyxFQUFDLE1BQU0sMEJBQTBCO09BQ2pFLEVBQUMsY0FBYyxFQUFDLE1BQU0sMkJBQTJCO09BQ2pELEVBQUMsU0FBUyxFQUFDLE1BQU0sa0NBQWtDO09BQ25ELEVBQUMsV0FBVyxFQUFDLE1BQU0sb0NBQW9DO09BQ3ZELEVBQUMsZ0JBQWdCLEVBQUMsTUFBTSxzQkFBc0I7T0FDOUMsRUFBQyx1QkFBdUIsRUFBRSxxQkFBcUIsRUFBbUIsYUFBYSxFQUFDLE1BQU0sUUFBUTtPQUM5RixFQUFDLFVB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QSxDQUFDQSxhQUFhQSxFQUFFQSxJQUFJQSxDQUFDQSxFQUFFQSxZQUFZQSxDQUFDQSxDQUFDQTtJQUNwRkEsQ0FBQ0E7SUFFT1IsYUFBYUEsQ0FBQ0EsS0FBYUEsRUFBRUEsSUFBYUE7UUFDaERTLE1BQU1BLENBQUNBLElBQUlBLEdBQUdBLElBQUlBLENBQUNBLFVBQVVBLENBQUNBLFdBQVdBLENBQUNBLEtBQUtBLEVBQUVBLFlBQVlBLEVBQUVBLFNBQVNBLENBQUNBLEdBQUdBLEtBQUtBLENBQUNBO0lBQ3BGQSxDQUFDQTtJQUVPVCxnQkFBZ0JBLENBQUNBLGFBQXFCQSxFQUFFQSxJQUFhQTtRQUMzRFUsTUFBTUEsQ0FBQ0EsSUFBSUEsR0FBR0EsR0FBR0EsYUFBYUEsUUFBUUEsYUFBYUEsRUFBRUEsR0FBR0EsR0FBR0EsYUFBYUEsR0FBR0EsYUFBYUEsRUFBRUEsQ0FBQ0E7SUFDN0ZBLENBQUNBO0FBQ0hWLENBQUNBO0FBckZEO0lBQUMsVUFBVSxFQUFFOztrQkFxRlo7QUFBQSIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCB7Q29tcGlsZVR5cGVNZXRhZGF0YSwgQ29tcGlsZVRlbXBsYXRlTWV0YWRhdGF9IGZyb20gJy4vZGlyZWN0aXZlX21ldGFkYXRhJztcbmltcG9ydCB7U291cmNlTW9kdWxlLCBTb3VyY2VFeHByZXNzaW9uLCBtb2R1bGVSZWZ9IGZyb20gJy4vc291cmNlX21vZHVsZSc7XG5pbXBvcnQge1ZpZXdFbmNhcHN1bGF0aW9ufSBmcm9tICdhbmd1bGFyMi9zcmMvY29yZS9tZXRhZGF0YS92aWV3JztcbmltcG9ydCB7WEhSfSBmcm9tICdhbmd1bGFyMi9zcmMvY29tcGlsZXIveGhyJztcbmltcG9ydCB7SVNfREFSVCwgU3RyaW5nV3JhcHBlciwgaXNCbGFua30gZnJvbSAnYW5ndWxhcjIvc3JjL2ZhY2FkZS9sYW5nJztcbmltcG9ydCB7UHJvbWlzZVdyYXBwZXJ9IGZyb20gJ2FuZ3VsYXIyL3NyYy9mYWNhZGUvYXN5bmMnO1xuaW1wb3J0IHtTaGFkb3dDc3N9IGZyb20gJ2FuZ3VsYXIyL3NyYy9jb21waWxlci9zaGFkb3dfY3NzJztcbmltcG9ydCB7VXJsUmVzb2x2ZXJ9IGZyb20gJ2FuZ3VsYXIyL3NyYy9jb21waWxlci91cmxfcmVzb2x2ZXInO1xuaW1wb3J0IHtleHRyYWN0U3R5bGVVcmxzfSBmcm9tICcuL3N0eWxlX3VybF9yZXNvbHZlcic7XG5pbXBvcnQge2VzY2FwZVNpbmdsZVF1b3RlU3RyaW5nLCBjb2RlR2VuRXhwb3J0VmFyaWFibGUsIGNvZGVHZW5Ub1N0cmluZywgTU9EVUxFX1NVRkZJWH0gZnJvbSAnLi91dGlsJztcbmltcG9ydCB7SW5qZWN0YWJsZX0gZnJvbSAnYW5ndWxhcjIvc3JjL2NvcmUvZGknO1xuXG5jb25zdCBDT01QT05FTlRfVkFSSUFCTEUgPSAnJUNPTVAlJztcbmNvbnN0IEhPU1RfQVRUUiA9IGBfbmdob3N0LSR7Q09NUE9ORU5UX1ZBUklBQkxFfWA7XG5jb25zdCBDT05URU5UX0FUVFIgPSBgX25nY29udGVudC0ke0NPTVBPTkVOVF9WQVJJQUJMRX1gO1xuXG5ASW5qZWN0YWJsZSgpXG5leHBvcnQgY2xhc3MgU3R5bGVDb21waWxlciB7XG4gIHByaXZhdGUgX3N0eWxlQ2FjaGU6IE1hcDxzdHJpbmcsIFByb21pc2U8c3RyaW5nW10+PiA9IG5ldyBNYXA8c3RyaW5nLCBQcm9taXNlPHN0cmluZ1tdPj4oKTtcbiAgcHJpdmF0ZSBfc2hhZG93Q3NzOiBTaGFkb3dDc3MgPSBuZXcgU2hhZG93Q3NzKCk7XG5cbiAgY29uc3RydWN0b3IocHJpdmF0ZSBfeGhyOiBYSFIsIHByaXZhdGUgX3VybFJlc29sdmVyOiBVcmxSZXNvbHZlcikge31cblxuICBjb21waWxlQ29tcG9uZW50UnVudGltZSh0ZW1wbGF0ZTogQ29tcGlsZVRlbXBsYXRlTWV0YWRhdGEpOiBQcm9taXNlPEFycmF5PHN0cmluZ3xhbnlbXT4+IHtcbiAgICB2YXIgc3R5bGVzID0gdGVtcGxhdGUuc3R5bGVzO1xuICAgIHZhciBzdHlsZUFic1VybHMgPSB0ZW1wbGF0ZS5zdHlsZVVybHM7XG4gICAgcmV0dXJuIHRoaXMuX2xvYWRTdHlsZXMoXG4gICAgICAgIHN0eWxlcywgc3R5bGVBYnNVcmxzLCB0ZW1wbGF0ZS5lbmNhcHN1bGF0aW9uID09PSBWaWV3RW5jYXBzdWxhdGlvbi5FbXVsYXRlZCk7XG4gIH1cblxuICBjb21waWxlQ29tcG9uZW50Q29kZUdlbih0ZW1wbGF0ZTogQ29tcGlsZVRlbXBsYXRlTWV0YWRhdGEpOiBTb3VyY2VFeHByZXNzaW9uIHtcbiAgICB2YXIgc2hpbSA9IHRlbXBsYXRlLmVuY2Fwc3VsYXRpb24gPT09IFZpZXdFbmNhcHN1bGF0aW9uLkVtdWxhdGVkO1xuICAgIHJldHVybiB0aGlzLl9zdHlsZUNvZGVHZW4odGVtcGxhdGUuc3R5bGVzLCB0ZW1wbGF0ZS5zdHlsZVVybHMsIHNoaW0pO1xuICB9XG5cbiAgY29tcGlsZVN0eWxlc2hlZXRDb2RlR2VuKHN0eWxlc2hlZXRVcmw6IHN0cmluZywgY3NzVGV4dDogc3RyaW5nKTogU291cmNlTW9kdWxlW10ge1xuICAgIHZhciBzdHlsZVdpdGhJbXBvcnRzID0gZXh0cmFjdFN0eWxlVXJscyh0aGlzLl91cmxSZXNvbHZlciwgc3R5bGVzaGVldFVybCwgY3NzVGV4dCk7XG4gICAgcmV0dXJuIFtcbiAgICAgIHRoaXMuX3N0eWxlTW9kdWxlKFxuICAgICAgICAgIHN0eWxlc2hlZXRVcmwsIGZhbHNlLFxuICAgICAgICAgIHRoaXMuX3N0eWxlQ29kZUdlbihbc3R5bGVXaXRoSW1wb3J0cy5zdHlsZV0sIHN0eWxlV2l0aEltcG9ydHMuc3R5bGVVcmxzLCBmYWxzZSkpLFxuICAgICAgdGhpcy5fc3R5bGVNb2R1bGUoXG4gICAgICAgICAgc3R5bGVzaGVldFVybCwgdHJ1ZSxcbiAgICAgICAgICB0aGlzLl9zdHlsZUNvZGVHZW4oW3N0eWxlV2l0aEltcG9ydHMuc3R5bGVdLCBzdHlsZVdpdGhJbXBvcnRzLnN0eWxlVXJscywgdHJ1ZSkpXG4gICAgXTtcbiAgfVxuXG4gIGNsZWFyQ2FjaGUoKSB7IHRoaXMuX3N0eWxlQ2FjaGUuY2xlYXIoKTsgfVxuXG4gIHByaXZhdGUgX2xvYWRTdHlsZXMocGxhaW5TdHlsZXM6IHN0cmluZ1tdLCBhYnNVcmxzOiBzdHJpbmdbXSwgZW5jYXBzdWxhdGU6IGJvb2xlYW4pOlxuICAgICAgUHJvbWlzZTxBcnJheTxzdHJpbmd8YW55W10+PiB7XG4gICAgdmFyIHByb21pc2VzOiBQcm9taXNlPHN0cmluZ1tdPltdID0gYWJzVXJscy5tYXAoKGFic1VybDogc3RyaW5nKTogUHJvbWlzZTxzdHJpbmdbXT4gPT4ge1xuICAgICAgdmFyIGNhY2hlS2V5ID0gYCR7YWJzVXJsfSR7ZW5jYXBzdWxhdGUgPyAnLnNoaW0nIDogJyd9YDtcbiAgICAgIHZhciByZXN1bHQ6IFByb21pc2U8c3RyaW5nW10+ID0gdGhpcy5fc3R5bGVDYWNoZS5nZXQoY2FjaGVLZXkpO1xuICAgICAgaWYgKGlzQmxhbmsocmVzdWx0KSkge1xuICAgICAgICByZXN1bHQgPSB0aGlzLl94aHIuZ2V0KGFic1VybCkudGhlbigoc3R5bGUpID0+IHtcbiAgICAgICAgICB2YXIgc3R5bGVXaXRoSW1wb3J0cyA9IGV4dHJhY3RTdHlsZVVybHModGhpcy5fdXJsUmVzb2x2ZXIsIGFic1VybCwgc3R5bGUpO1xuICAgICAgICAgIHJldHVybiB0aGlzLl9sb2FkU3R5bGVzKFxuICAgICAgICAgICAgICBbc3R5bGVXaXRoSW1wb3J0cy5zdHlsZV0sIHN0eWxlV2l0aEltcG9ydHMuc3R5bGVVcmxzLCBlbmNhcHN1bGF0ZSk7XG4gICAgICAgIH0pO1xuICAgICAgICB0aGlzLl9zdHlsZUNhY2hlLnNldChjYWNoZUtleSwgcmVzdWx0KTtcbiAgICAgIH1cbiAgICAgIHJldHVybiByZXN1bHQ7XG4gICAgfSk7XG4gICAgcmV0dXJuIFByb21pc2VXcmFwcGVyLmFsbDxzdHJpbmdbXT4ocHJvbWlzZXMpLnRoZW4oKG5lc3RlZFN0eWxlczogc3RyaW5nW11bXSkgPT4ge1xuICAgICAgdmFyIHJlc3VsdDogQXJyYXk8c3RyaW5nfGFueVtdPiA9XG4gICAgICAgICAgcGxhaW5TdHlsZXMubWFwKHBsYWluU3R5bGUgPT4gdGhpcy5fc2hpbUlmTmVlZGVkKHBsYWluU3R5bGUsIGVuY2Fwc3VsYXRlKSk7XG4gICAgICBuZXN0ZWRTdHlsZXMuZm9yRWFjaChzdHlsZXMgPT4gcmVzdWx0LnB1c2goc3R5bGVzKSk7XG4gICAgICByZXR1cm4gcmVzdWx0O1xuICAgIH0pO1xuICB9XG5cbiAgcHJpdmF0ZSBfc3R5bGVDb2RlR2VuKHBsYWluU3R5bGVzOiBzdHJpbmdbXSwgYWJzVXJsczogc3RyaW5nW10sIHNoaW06IGJvb2xlYW4pOiBTb3VyY2VFeHByZXNzaW9uIHtcbiAgICB2YXIgYXJyYXlQcmVmaXggPSBJU19EQVJUID8gYGNvbnN0YCA6ICcnO1xuICAgIHZhciBzdHlsZUV4cHJlc3Npb25zID0gcGxhaW5TdHlsZXMubWFwKFxuICAgICAgICBwbGFpblN0eWxlID0+IGVzY2FwZVNpbmdsZVF1b3RlU3RyaW5nKHRoaXMuX3NoaW1JZk5lZWRlZChwbGFpblN0eWxlLCBzaGltKSkpO1xuXG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBhYnNVcmxzLmxlbmd0aDsgaSsrKSB7XG4gICAgICB2YXIgbW9kdWxlVXJsID0gdGhpcy5fY3JlYXRlTW9kdWxlVXJsKGFic1VybHNbaV0sIHNoaW0pO1xuICAgICAgc3R5bGVFeHByZXNzaW9ucy5wdXNoKGAke21vZHVsZVJlZihtb2R1bGVVcmwpfVNUWUxFU2ApO1xuICAgIH1cbiAgICB2YXIgZXhwcmVzc2lvblNvdXJjZSA9IGAke2FycmF5UHJlZml4fSBbJHtzdHlsZUV4cHJlc3Npb25zLmpvaW4oJywnKX1dYDtcbiAgICByZXR1cm4gbmV3IFNvdXJjZUV4cHJlc3Npb24oW10sIGV4cHJlc3Npb25Tb3VyY2UpO1xuICB9XG5cbiAgcHJpdmF0ZSBfc3R5bGVNb2R1bGUoc3R5bGVzaGVldFVybDogc3RyaW5nLCBzaGltOiBib29sZWFuLCBleHByZXNzaW9uOiBTb3VyY2VFeHByZXNzaW9uKTpcbiAgICAgIFNvdXJjZU1vZHVsZSB7XG4gICAgdmFyIG1vZHVsZVNvdXJjZSA9IGBcbiAgICAgICR7ZXhwcmVzc2lvbi5kZWNsYXJhdGlvbnMuam9pbignXFxuJyl9XG4gICAgICAke2NvZGVHZW5FeHBvcnRWYXJpYWJsZSgnU1RZTEVTJyl9JHtleHByZXNzaW9uLmV4cHJlc3Npb259O1xuICAgIGA7XG4gICAgcmV0dXJuIG5ldyBTb3VyY2VNb2R1bGUodGhpcy5fY3JlYXRlTW9kdWxlVXJsKHN0eWxlc2hlZXRVcmwsIHNoaW0pLCBtb2R1bGVTb3VyY2UpO1xuICB9XG5cbiAgcHJpdmF0ZSBfc2hpbUlmTmVlZGVkKHN0eWxlOiBzdHJpbmcsIHNoaW06IGJvb2xlYW4pOiBzdHJpbmcge1xuICAgIHJldHVybiBzaGltID8gdGhpcy5fc2hhZG93Q3NzLnNoaW1Dc3NUZXh0KHN0eWxlLCBDT05URU5UX0FUVFIsIEhPU1RfQVRUUikgOiBzdHlsZTtcbiAgfVxuXG4gIHByaXZhdGUgX2NyZWF0ZU1vZHVsZVVybChzdHlsZXNoZWV0VXJsOiBzdHJpbmcsIHNoaW06IGJvb2xlYW4pOiBzdHJpbmcge1xuICAgIHJldHVybiBzaGltID8gYCR7c3R5bGVzaGVldFVybH0uc2hpbSR7TU9EVUxFX1NVRkZJWH1gIDogYCR7c3R5bGVzaGVldFVybH0ke01PRFVMRV9TVUZGSVh9YDtcbiAgfVxufVxuIl19