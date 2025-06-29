(function () {
    'use strict';

    var extend = function () {
        var length = arguments.length;
        var target = arguments[0] || {};
        if (typeof target != "object" && typeof target != "function") {
            target = {};
        }
        if (length == 1) {
            target = this;
            i--;
        }
        for (var i = 1; i < length; i++) {
            var source = arguments[i];
            for (var key in source) {
                if (Object.prototype.hasOwnProperty.call(source, key)) {
                    target[key] = source[key];
                }
            }
        }
        return target;
    }

    var isFunction = function isFunction(obj) {
        return typeof obj === "function" && typeof obj.nodeType !== "number";
    };

    var SliderCaptcha = function (element, options) {
        this.$element = element;
        this.options = extend({}, SliderCaptcha.DEFAULTS, options);
        this.$element.style.position = 'relative';
        this.$element.style.width = this.options.width + 'px';
        this.$element.style.margin = '0 auto';
        this.init();
    };

    
    
    SliderCaptcha.DEFAULTS = {
        width: 280,    
        height: 220,  
        PI: Math.PI,
        sliderL: 42,    
        sliderR: 9,    
        offset: 5,     
        loadingText: 'Loading...',
        failedText: 'Try Again',
        barText: 'Slide To Verify',
        repeatIcon: 'fas fa-redo',
        captcha: 'true',
        maxLoadCount: 3,
        localImages: function () {
            return 'assets/Pic' + Math.round(Math.random() * 4) + '.jpg';
        },
        verify: function (arr, url) {
            var ret = false;
            $.ajax({
                url: url,
                data: {
                    "datas": JSON.stringify(arr),
                },
                dataType: "json",
                type: "post",
                async: false,
                success: function (result) {
                    ret = JSON.stringify(result);
                    console.log("Result: " + ret)
                }
            });
            return ret;
        },
        remoteUrl: null
    };

    function Plugin(option) {
        var $this = document.getElementById(option.id);
        var options = typeof option === 'object' && option;
        return new SliderCaptcha($this, options);
    }

    window.sliderCaptcha = Plugin;
    window.sliderCaptcha.Constructor = SliderCaptcha;

    var _proto = SliderCaptcha.prototype;
    _proto.init = function () {
        this.initDOM();
        this.initImg();
        this.bindEvents();
    };

    _proto.initDOM = function () {
        var createElement = function (tagName, className) {
            var elment = document.createElement(tagName);
            elment.className = className;
            return elment;
        };

        var createCanvas = function (width, height) {
            var canvas = document.createElement('canvas');
            canvas.width = width;
            canvas.height = height;
            return canvas;
        };

        var canvas = createCanvas(this.options.width - 2, this.options.height);
        var block = canvas.cloneNode(true); 
        var sliderContainer = createElement('div', 'sliderContainer');
        var refreshIcon = createElement('i', 'refreshIcon ' + this.options.repeatIcon);
        var sliderMask = createElement('div', 'sliderMask');
        var sliderbg = createElement('div', 'sliderbg');
        var slider = createElement('div', 'slider');
        var sliderIcon = createElement('i', 'fa fa-arrow-right sliderIcon');
        var text = createElement('span', 'sliderText');
        var inputTag = createElement('input','captchaCheck');

        block.className = 'block';
        text.innerHTML = this.options.barText;
        inputTag.innerHTML = this.options.captcha;
        var el = this.$element;
        el.appendChild(canvas);
        el.appendChild(refreshIcon);
        el.appendChild(block);
        slider.appendChild(sliderIcon);
        sliderMask.appendChild(slider);
        sliderContainer.appendChild(sliderbg);
        sliderContainer.appendChild(sliderMask);
        sliderContainer.appendChild(text);
        el.appendChild(sliderContainer);

        var _canvas = {
            canvas: canvas,
            block: block,
            sliderContainer: sliderContainer,
            refreshIcon: refreshIcon,
            slider: slider,
            sliderMask: sliderMask,
            sliderIcon: sliderIcon,
            text: text,
            canvasCtx: canvas.getContext('2d'),
            blockCtx: block.getContext('2d')
        };

        if (isFunction(Object.assign)) {
            Object.assign(this, _canvas);
        }
        else {
            extend(this, _canvas);
        }
    };

    _proto.initImg = function () {
        var that = this;
        var isIE = window.navigator.userAgent.indexOf('Trident') > -1;
        var L = this.options.sliderL + this.options.sliderR * 2 + 3;
        var drawImg = function (ctx, operation) {
            var l = that.options.sliderL;
            var r = that.options.sliderR;
            var PI = that.options.PI;
            var x = that.x;
            var y = that.y;
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.arc(x + l / 2, y - r + 2, r, 0.72 * PI, 2.26 * PI);
            ctx.lineTo(x + l, y);
            ctx.arc(x + l + r - 2, y + l / 2, r, 1.21 * PI, 2.78 * PI);
            ctx.lineTo(x + l, y + l);
            ctx.lineTo(x, y + l);
            ctx.arc(x + r - 2, y + l / 2, r + 0.4, 2.76 * PI, 1.24 * PI, true);
            ctx.lineTo(x, y);
            ctx.lineWidth = 2;
            ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.7)';
            ctx.stroke();
            ctx[operation]();
            ctx.globalCompositeOperation = isIE ? 'xor' : 'destination-over';
        };

        var getRandomNumberByRange = function (start, end) {
            return Math.round(Math.random() * (end - start) + start);
        };
        var img = new Image();
        img.crossOrigin = "Anonymous";
        var loadCount = 0;
        img.onload = function () {
            
            that.x = getRandomNumberByRange(L + 10, that.options.width - (L + 10));
            that.y = getRandomNumberByRange(10 + that.options.sliderR * 2, that.options.height - (L + 10));
            drawImg(that.canvasCtx, 'fill');
            drawImg(that.blockCtx, 'clip');

            that.canvasCtx.drawImage(img, 0, 0, that.options.width - 2, that.options.height);
            that.blockCtx.drawImage(img, 0, 0, that.options.width - 2, that.options.height);
            var y = that.y - that.options.sliderR * 2 - 1;
            var ImageData = that.blockCtx.getImageData(that.x - 3, y, L, L);
            that.block.width = L;
            that.blockCtx.putImageData(ImageData, 0, y + 1);
            that.text.textContent = that.text.getAttribute('data-text');
        };
        img.onerror = function () {
            loadCount++;
            if (window.location.protocol === 'file:') {
                loadCount = that.options.maxLoadCount;
                console.error("can't load pic resource file from File protocal. Please try http or https");
            }
            if (loadCount >= that.options.maxLoadCount) {
                that.text.textContent = 'Failed To Load';
                that.classList.add('text-danger');
                return;
            }
            img.src = that.options.localImages();
        };
        img.setSrc = function () {
            var src = '';
            loadCount = 0;
            that.text.classList.remove('text-danger');
            if (isFunction(that.options.setSrc)) src = that.options.setSrc();
            if (!src || src === '') src = 'assets/Pic' + Math.round(Math.random() * 4) + '.jpg';
            if (isIE) {
                var xhr = new XMLHttpRequest();
                xhr.onloadend = function (e) {
                    var file = new FileReader(); 
                    file.readAsDataURL(e.target.response);
                    file.onloadend = function (e) {
                        img.src = e.target.result;
                    };
                };
                xhr.open('GET', src);
                xhr.responseType = 'blob';
                xhr.send();
            } else img.src = src;
        };
        img.setSrc();
        this.text.setAttribute('input-text', this.options.captcha);
        this.text.setAttribute('data-text', this.options.barText);
        this.text.textContent = this.options.loadingText;
        this.img = img;
    };

    _proto.clean = function () {
        this.canvasCtx.clearRect(0, 0, this.options.width, this.options.height);
        this.blockCtx.clearRect(0, 0, this.options.width, this.options.height);
        this.block.width = this.options.width;
    };

    _proto.bindEvents = function () {
        var that = this;
        this.$element.addEventListener('selectstart', function () {
            return false;
        });

        this.refreshIcon.addEventListener('click', function () {
            that.text.textContent = that.options.barText;
            that.reset();
            if (isFunction(that.options.onRefresh)) that.options.onRefresh.call(that.$element);
        });

        var originX, originY, trail = [],
            isMouseDown = false;

        var handleDragStart = function (e) {
            if (that.text.classList.contains('text-danger')) return;
            originX = e.clientX || e.touches[0].clientX;
            originY = e.clientY || e.touches[0].clientY;
            isMouseDown = true;
        };

        var handleDragMove = function (e) {
            if (!isMouseDown) return false;
            var eventX = e.clientX || e.touches[0].clientX;
            var eventY = e.clientY || e.touches[0].clientY;
            var moveX = eventX - originX;
            var moveY = eventY - originY;
            if (moveX < 0 || moveX + 40 > that.options.width) return false;
            that.slider.style.left = (moveX - 1) + 'px';
            var blockLeft = (that.options.width - 40 - 20) / (that.options.width - 40) * moveX;
            that.block.style.left = blockLeft + 'px';

            that.sliderContainer.classList.add('sliderContainer_active');
            that.sliderMask.style.width = (moveX + 4) + 'px';
            trail.push(Math.round(moveY));
        };

        var handleDragEnd = function (e) {
            if (!isMouseDown) return false;
            isMouseDown = false;
            var eventX = e.clientX || e.changedTouches[0].clientX;
            if (eventX === originX) return false;
            that.sliderContainer.classList.remove('sliderContainer_active');
            that.trail = trail;
            var data = that.verify();
            if (data.spliced && data.verified) {
                that.sliderContainer.classList.add('sliderContainer_success');
                if (isFunction(that.options.onSuccess)) that.options.onSuccess.call(that.$element);
            } else {
                that.sliderContainer.classList.add('sliderContainer_fail');
                if (isFunction(that.options.onFail)) that.options.onFail.call(that.$element);
                setTimeout(function () {
                    that.text.innerHTML = that.options.failedText;
                    that.reset();
                }, 1000);
            }
        };

        this.slider.addEventListener('mousedown', handleDragStart);
        this.slider.addEventListener('touchstart', handleDragStart);
        this.block.addEventListener('mousedown',handleDragStart);
        document.addEventListener('mousemove', handleDragMove);
        document.addEventListener('touchmove', handleDragMove);
        document.addEventListener('mouseup', handleDragEnd);
        document.addEventListener('touchend', handleDragEnd);
        

        document.addEventListener('mousedown', function () { return false; });
        document.addEventListener('touchstart', function () { return false; });
        document.addEventListener('swipe', function () { return false; });
    };

    _proto.verify = function () {
        var arr = this.trail;
        var left = parseInt(this.block.style.left);
        var verified = false;
        if (this.options.remoteUrl !== null) {
            verified = this.options.verify(arr, this.options.remoteUrl);
        }
        else {
            var sum = function (x, y) { return x + y; };
            var square = function (x) { return x * x; };
            var average = arr.reduce(sum) / arr.length;
            var deviations = arr.map(function (x) { return x - average; });
            var stddev = Math.sqrt(deviations.map(square).reduce(sum) / arr.length);
            verified = stddev !== 0;
        }
        return {
            spliced: Math.abs(left - this.x) < this.options.offset,
            verified: verified
        };
    };

    _proto.reset = function () {
        this.sliderContainer.classList.remove('sliderContainer_fail');
        this.sliderContainer.classList.remove('sliderContainer_success');
        this.slider.style.left = 0;
        this.block.style.left = 0;
        this.sliderMask.style.width = 0;
        this.clean();
        this.text.setAttribute('data-text', this.text.textContent);
        this.text.textContent = this.options.loadingText;
        this.img.setSrc();
    };
})();
