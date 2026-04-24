import dynamic from "next/dynamic";

const ReactQuill = dynamic(() => import("react-quill"), {
  ssr: false,
  loading: () => <div className="editor-loading">Loading editor...</div>
});

const modules = {
  toolbar: [
    [{ header: [1, 2, 3, false] }],
    ["bold", "italic", "underline", "strike"],
    [{ list: "ordered" }, { list: "bullet" }],
    ["blockquote", "code-block"],
    ["link"],
    ["clean"]
  ]
};

export default function Editor({
  value,
  onChange
}: {
  value: string;
  onChange: (value: string) => void;
}) {
  return <ReactQuill theme="snow" value={value} onChange={onChange} modules={modules} />;
}
