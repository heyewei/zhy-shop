[#escape x as x?html]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<title>${message("shop.cart.title")}[#if showPowered][/#if]</title>
<meta name="author" content="SHOP++ Team" />
<meta name="copyright" content="SHOP++" />
<link href="${base}/resources/shop/${theme}/css/common.css" rel="stylesheet" type="text/css" />
<link href="${base}/resources/shop/${theme}/css/cart.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="${base}/resources/shop/${theme}/js/jquery.js"></script>
<script type="text/javascript" src="${base}/resources/shop/${theme}/js/common.js"></script>
<script type="text/javascript">
$().ready(function() {

	var $quantity = $(".cartTable input[name='quantity']");
	var $increase = $(".cartTable span.increase");
	var $decrease = $(".cartTable span.decrease");
	var $delete = $(".cartTable a.delete");
	var $promotion = $("#promotion");
	var $promotionDiscount = $("#promotionDiscount");
	var $effectiveRewardPoint = $("#effectiveRewardPoint");
	var $effectivePrice = $("#effectivePrice");
	var $clear = $("#clear");
	var $submit = $("#submit");
	var timeouts = {};
	
	// 初始数量
	$quantity.each(function() {
		var $this = $(this);
		$this.data("value", $this.val());
	});
	
	// 数量
	$quantity.keypress(function(event) {
		return (event.which >= 48 && event.which <= 57) || event.which == 8;
	});
	
	// 增加数量
	$increase.click(function() {
		var $quantity = $(this).siblings("input");
		var quantity = $quantity.val();
		if (/^\d*[1-9]\d*$/.test(quantity)) {
			$quantity.val(parseInt(quantity) + 1);
		} else {
			$quantity.val(1);
		}
		edit($quantity);
	});
	
	// 减少数量
	$decrease.click(function() {
		var $quantity = $(this).siblings("input");
		var quantity = $quantity.val();
		if (/^\d*[1-9]\d*$/.test(quantity) && parseInt(quantity) > 1) {
			$quantity.val(parseInt(quantity) - 1);
		} else {
			$quantity.val(1);
		}
		edit($quantity);
	});
	
	// 编辑数量
	$quantity.on("input propertychange change", function(event) {
		if (event.type != "propertychange" || event.originalEvent.propertyName == "value") {
			edit($(this));
		}
	});
	
	// 编辑数量
	function edit($quantity) {
		var quantity = $quantity.val();
		var $gift = $quantity.closest("tbody [class='cartTbody']").find("dl.gift");
		var $promotion = $quantity.closest("tbody [class='cartTbody']").find("em.promotion");
		if (/^\d*[1-9]\d*$/.test(quantity)) {
			var $tr = $quantity.closest("tr");
			var id = $tr.find("input[name='id']").val();
			clearTimeout(timeouts[id]);
			timeouts[id] = setTimeout(function() {
				$.ajax({
					url: "edit.jhtml",
					type: "POST",
					data: {id: id, quantity: quantity},
					dataType: "json",
					cache: false,
					beforeSend: function() {
						$submit.prop("disabled", true);
					},
					success: function(data) {
						if (data.message.type == "success") {
							$quantity.data("value", quantity);
							$tr.find("span.subtotal").text(currency(data.subtotal, true));
							if (data.giftNames != null && data.giftNames.length > 0) {
								$gift.html('<dt>${message("Cart.gifts")}:<\/dt>');
								$.each(data.giftNames, function(i, giftName) {
									$gift.append('<dd title="' + escapeHtml(giftName) + '">' + escapeHtml(abbreviate(giftName, 50)) + ' &times; 1<\/dd>');
								});
								"opacity" in document.documentElement.style ? $gift.fadeIn() : $gift.show();
							} else {
								"opacity" in document.documentElement.style ? $gift.fadeOut() : $gift.hide();
							}
							$promotion.text(data.promotionNames.join(", "));
							if (!data.isLowStock) {
								$tr.find("span.lowStock").remove();
							}
							$effectiveRewardPoint.text(data.effectiveRewardPoint);
							$effectivePrice.text(currency(data.effectivePrice, true, true));
							$promotionDiscount.text(currency(data.promotionDiscount, true, true));
						} else if (data.message.type == "warn") {
							$.message(data.message);
							$quantity.val($quantity.data("value"));
						} else if (data.message.type == "error") {
							$.message(data.message);
							$quantity.val($quantity.data("value"));
							setTimeout(function() {
								location.reload(true);
							}, 3000);
						}
					},
					complete: function() {
						$submit.prop("disabled", false);
					}
				});
			}, 500);
		} else {
			$quantity.val($quantity.data("value"));
		}
	}
	
	// 删除
	$delete.click(function() {
		if (confirm("${message("shop.dialog.deleteConfirm")}")) {
			var $this = $(this);
			var $tr = $this.closest("tr");
			var id = $tr.find("input[name='id']").val();
			var $gift = $this.closest("tbody [class='cartTbody']").find("dl.gift");
			var $promotion = $this.closest("tbody [class='cartTbody']").find("em.promotion");
			$.ajax({
				url: "delete.jhtml",
				type: "POST",
				data: {id: id},
				dataType: "json",
				cache: false,
				beforeSend: function() {
					$submit.prop("disabled", true);
				},
				success: function(data) {
					if (data.message.type == "success") {
						if (data.quantity > 0) {
							$tr.remove();
							if (data.giftNames != null && data.giftNames.length > 0) {
								$gift.html('<dt>${message("Cart.gifts")}:<\/dt>');
								$.each(data.giftNames, function(i, giftName) {
									$gift.append('<dd title="' + escapeHtml(giftName) + '">' + escapeHtml(abbreviate(giftName, 50)) + ' &times; 1<\/dd>');
								});
								"opacity" in document.documentElement.style ? $gift.fadeIn() : $gift.show();
							} else {
								"opacity" in document.documentElement.style ? $gift.fadeOut() : $gift.hide();
							}
							$promotion.text(data.promotionNames.join(", "));
							$effectiveRewardPoint.text(data.effectiveRewardPoint);
							$effectivePrice.text(currency(data.effectivePrice, true, true));
							$promotionDiscount.text(currency(data.promotionDiscount, true, true));
						} else {
							location.reload(true);
						}
					} else {
						$.message(data.message);
						setTimeout(function() {
							location.reload(true);
						}, 3000);
					}
				},
				complete: function() {
					$submit.prop("disabled", false);
				}
			});
		}
		return false;
	});
	
	// 清空
	$clear.click(function() {
		if (confirm("${message("shop.dialog.clearConfirm")}")) {
			$.each(timeouts, function(i, timeout) {
				clearTimeout(timeout);
			});
			$.ajax({
				url: "clear.jhtml",
				type: "POST",
				dataType: "json",
				cache: false,
				success: function(data) {
					location.reload(true);
				}
			});
		}
		return false;
	});
	
	// 提交
	$submit.click(function() {
		if (!$.checkLogin()) {
			$.redirectLogin("${base}/cart/list.jhtml", "${message("shop.cart.accessDenied")}");
			return false;
		}
	});

});
</script>
</head>
<body>
	[#include "/shop/${theme}/include/header.ftl" /]
	<div class="container cart">
		<div class="row">
			<div class="span12">
				<div class="step">
					<ul>
						<li class="current">${message("shop.cart.step1")}</li>
						<li>${message("shop.cart.step2")}</li>
						<li>${message("shop.cart.step3")}</li>
					</ul>
				</div>
				[#if cart?? && cart.cartItems?has_content && cart.stores?has_content]
					<table class="cartTable">
						<tr class="title" >
							<th>${message("shop.cart.product")}</th>
							<th>${message("shop.cart.price")}</th>
							<th>${message("shop.cart.quantity")}</th>
							<th>${message("shop.cart.subtotal")}</th>
							<th>${message("shop.cart.action")}</th>
						</tr>
						[#list cart.stores as store]
							<tbody class="cartDiv">
								[#list cart.getCartItems(store) as cartItem]
									<tr>
										<td>
											<input type="hidden" name="id" value="${cartItem.product.id}" />
											<img src="${cartItem.product.thumbnail!setting.defaultThumbnailProductImage}" alt="${abbreviate(cartItem.product.name, 50, "...")}" />
											<a href="${cartItem.product.url}" title="${cartItem.product.name}" target="_blank">${abbreviate(cartItem.product.name, 50, "...")}</a>
											[#if cartItem.product.specifications?has_content]
												<span class="silver">[${cartItem.product.specifications?join(", ")}]</span>
											[/#if]
											[#if !cartItem.isMarketable]
												<span class="red">[${message("shop.cart.notMarketable")}]</span>
											[/#if]
											[#if cartItem.isLowStock]
												<span class="red lowStock">[${message("shop.cart.lowStock")}]</span>
											[/#if]
											[#if !cartItem.isActive]
												<span class="red">[${message("shop.cart.isActive")}]</span>
											[/#if]
										</td>
										<td>
											${currency(cartItem.price, true)}
											<span class="total">
												<em class="promotion">${cartItem.getPromotionNames(store)?join(", ")}</em>
											</span>	
										</td>
										<td class="quantity" width="130">
											<span class="decrease">-</span>
											<input type="text" name="quantity" value="${cartItem.quantity}" maxlength="4" onpaste="return false;" />
											<span class="increase">+</span>
										</td>
										<td>
											<span class="subtotal">${currency(cartItem.subtotal, true)}</span>
										</td>
										<td style="width:100px;text-align:right;">
											<a href="javascript:;" class="delete">${message("shop.cart.delete")}</a>
										</td>
									</tr>
								[/#list]
								[#if cart.getGiftNames(store)?has_content || cart.getPromotionNames(store)?has_content]
									<tr[#if !cart.getGiftNames(store)?has_content] hidden[/#if]>
										<td colspan="6">
											<dl class="gift clearfix">
												[#if cart.getGiftNames(store)?has_content]
													<dt>${message("Cart.gifts")}:</dt>
													[#list cart.getGiftNames(store) as giftName]
														<dd title="${giftName}">${abbreviate(giftName, 50)} &times; 1</dd>
													[/#list]
												[/#if]
											</dl>
										</td>
									</tr>
								[/#if]
							</tbody>
						[/#list]
					</table>
				[#else]
					<p>
						<a href="${base}/">${message("shop.cart.empty")}</a>
					</p>
				[/#if]
			</div>
		</div>
		[#if cart?? && cart.cartItems?has_content]
			<div class="total">
				${message("shop.cart.effectivePrice")}: <strong id="effectivePrice">${currency(cart.getEffectivePriceTotal(cart.stores), true, true)}</strong>
			</div>
			<div class="row">
				<div class="span12">
					<div class="bottom">
						<span class="total">
							[@current_member]
								[#if !currentMember??]
									<em>${message("shop.cart.promotionTips")}</em>
								[#else]
									${message("shop.cart.promotionDiscount")}: <em id="promotionDiscount">${currency(cart.getDiscountTotal(cart.stores),true,true)}</em>	
								[/#if]
							[/@current_member]
							${message("shop.cart.effectiveRewardPoint")}: <em id="effectiveRewardPoint">${cart.getEffectiveRewardPointTotal(cart.stores)}</em>
							
						</span>
						<span>
							<a href="javascript:;" id="clear" class="clear">${message("shop.cart.clear")}</a>
							<a href="${base}/order/checkout.jhtml" id="submit" class="submit">${message("shop.cart.submit")}</a>
						</span>
					</div>
				</div>
			</div>
		[/#if]
	</div>
	[#include "/shop/${theme}/include/footer.ftl" /]
</body>
</html>
[/#escape]