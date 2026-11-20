-- Turn GitHub alerts ("> [!NOTE]" quotes) into divs classed by type,
-- matching Org's special blocks ("#+begin_note").
local kinds = { note = true, tip = true, important = true, warning = true, caution = true }

function BlockQuote(quote)
  local para = quote.content[1]
  if not para or para.t ~= "Para" or not para.content[1] or para.content[1].t ~= "Str" then
    return nil
  end
  local kind = para.content[1].text:match("^%[!(%u+)%]$")
  kind = kind and kind:lower()
  if not kinds[kind] then
    return nil
  end
  para.content:remove(1)
  while para.content[1] and (para.content[1].t == "SoftBreak" or para.content[1].t == "LineBreak"
                             or para.content[1].t == "Space") do
    para.content:remove(1)
  end
  if #para.content == 0 then
    quote.content:remove(1)
  end
  return pandoc.Div(quote.content, { class = kind })
end
