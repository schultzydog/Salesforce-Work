import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const DEFAULT_OBJECT = 'Contact';
const DEFAULT_URL_FIELD = 'Retool_Id__c';
// Deliberately not {!value}: Lightning App Builder parses {!...} in a property
// value as a merge-field binding and rejects it at deploy time.
const VALUE_TOKEN = '{value}';
const ANCHOR_HREF = /<a\b[^>]*\bhref\s*=\s*["']([^"']+)["']/i;
// Scopes the Retool app to the preferences view. Flipped to false when opening
// in a new tab, where the full contact page is wanted instead. Matched by string
// rather than URL.searchParams, which Lightning Locker's SecureURL omits.
const FRAME_ONLY_PARAM = 'subsonly';
const FRAME_ONLY_PATTERN = /([?&])subsonly=[^&#]*/;
const MIN_HEIGHT = 200;
const MAX_HEIGHT = 2000;
const DEFAULT_HEIGHT = 600;

const HTML_ENTITIES = {
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>'
};

export default class ContactUrlFrame extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api cardTitle = 'Contact Web View';
    @api urlFieldApiName = DEFAULT_URL_FIELD;
    @api urlTemplate;
    @api frameHeight = DEFAULT_HEIGHT;

    fieldValue;

    _fields;
    _fieldsKey;
    _wireError;
    _wireLoading = true;

    // A template with no placeholder is a fixed destination, so nothing on the
    // record can affect it and the wire result is irrelevant.
    get hasStaticUrl() {
        const template = (this.urlTemplate || '').trim();
        return Boolean(template) && !template.includes(VALUE_TOKEN);
    }

    get isLoading() {
        return this.hasStaticUrl ? false : this._wireLoading;
    }

    get errorMessage() {
        return this.hasStaticUrl ? undefined : this._wireError;
    }

    // Memoized so the wire config keeps a stable array identity across re-renders.
    get fieldsToQuery() {
        const objectName = this.objectApiName || DEFAULT_OBJECT;
        const fieldName = (this.urlFieldApiName || DEFAULT_URL_FIELD).trim();
        const key = `${objectName}.${fieldName}`;
        if (this._fieldsKey !== key) {
            this._fieldsKey = key;
            this._fields = [key];
        }
        return this._fields;
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldsToQuery' })
    wiredRecord({ data, error }) {
        this._wireLoading = false;
        if (data) {
            this._wireError = undefined;
            this.fieldValue = getFieldValue(data, this.fieldsToQuery[0]);
        } else if (error) {
            this.fieldValue = undefined;
            this._wireError = reduceError(error);
        }
    }

    get frameUrl() {
        if (this.hasStaticUrl) {
            return toHttpsUrl(this.urlTemplate);
        }

        const raw = this.fieldValue;
        if (raw === null || raw === undefined) {
            return undefined;
        }

        const value = String(raw).trim();
        if (!value) {
            return undefined;
        }

        // A HYPERLINK() formula returns anchor markup, which already carries the
        // full destination, so the template has nothing left to contribute.
        const anchor = ANCHOR_HREF.exec(value);
        if (anchor) {
            return toHttpsUrl(decodeEntities(anchor[1]));
        }

        const template = (this.urlTemplate || '').trim();
        if (template) {
            return toHttpsUrl(
                template.split(VALUE_TOKEN).join(encodeURIComponent(value))
            );
        }

        return toHttpsUrl(value);
    }

    get frameStyle() {
        return `height: ${this.resolvedHeight}px;`;
    }

    get resolvedHeight() {
        const parsed = parseInt(this.frameHeight, 10);
        if (Number.isNaN(parsed)) {
            return DEFAULT_HEIGHT;
        }
        return Math.min(Math.max(parsed, MIN_HEIGHT), MAX_HEIGHT);
    }

    get cannotOpen() {
        return !this.frameUrl;
    }

    get newTabUrl() {
        const url = this.frameUrl;
        if (!url) {
            return undefined;
        }
        return url.replace(FRAME_ONLY_PATTERN, `$1${FRAME_ONLY_PARAM}=false`);
    }

    handleOpenInNewTab() {
        const url = this.newTabUrl;
        if (url) {
            window.open(url, '_blank', 'noopener,noreferrer');
        }
    }
}

function toHttpsUrl(candidate) {
    const url = (candidate || '').trim();
    return url.toLowerCase().startsWith('https://') ? url : undefined;
}

function decodeEntities(value) {
    return Object.keys(HTML_ENTITIES).reduce(
        (result, entity) => result.split(entity).join(HTML_ENTITIES[entity]),
        value
    );
}

function reduceError(error) {
    const body = error && error.body;
    if (Array.isArray(body)) {
        return body.map((entry) => entry.message).join(', ');
    }
    if (body && body.message) {
        return body.message;
    }
    if (error && error.message) {
        return error.message;
    }
    return 'Unable to load this record.';
}